#!/usr/bin/env bash
# setup-env.sh requires bash

# Configuration
DXRCONFIG=$1
TREE="$2"
REMOTE="$3"
CURRENTDIR=`pwd`

if [ ! -f $DXRCONFIG ]; then
  if [ -f /etc/dxr/dxr.config ]; then
    DXRCONFIG=/etc/dxr/dxr.config
  else
    DXRCONFIG=dxr.config
  fi
fi

echo $DXRCONFIG

readconfig() {
  echo "reading $2 from section '$1'" >&2
  cat $DXRCONFIG | sed -n "/^\[$1\]/,/^\[.*\]/p" | grep "^[[:space:]]*$2[[:space:]]*=" | sed "s/[^=]*=[:space:]*//"
}
SOURCE=`readconfig $TREE sourcedir`
BUILD=`readconfig $TREE objdir`
VCSPULL=`readconfig $TREE pullcommand`
BUILDCMD=`readconfig $TREE buildcommand`
DXRROOT=`readconfig DXR dxrroot`
WWWROOT=`readconfig Web wwwdir`

if [ "$DXRCONFIG" == "" -o "$TREE" == "" -o "$SOURCE" == "" -o "$BUILD" == "" -o "$VCSPULL" == "" -o "$BUILDCMD" == "" ]; then
  echo Usage: $0 DXRCONFIG TREE [REMOTE]
  echo The section [$TREE] must contain 'pullcommand' and 'buildcommand' keys in the configuration.
  exit 1
fi

PATH="/opt/dxr/bin/:$PATH"
MAKEFLAGS='-j4 -s V=0'; export MAKEFLAGS
CFLAGS=-std=gnu89; export CFLAGS
# FIXME: disable warning: extension used [-pedantic]

test "`command -v clang`" == "" && echo Failed: clang not found && exit 1
# FIXME: the generic check doesn't work on Debian squeeze
# for i in `egrep -hR '^\s*import [^"]' $DXRROOT/*.py | grep -v dxr | sed -e 's/^[ \t]*//'`; do python -c "$i"; done || (echo Failed: Missing Python modules && exit 1)
python -c 'import xdg.Mime, sqlite3, subprocess' || (echo Failed: Missing Python modules && exit 1)

# Source
cd $CURRENTDIR
. $DXRROOT/setup-env.sh $DXRCONFIG $TREE || exit 1
echo ' '

cd $SOURCE
$SHELL -c "$VCSPULL"
echo ' '

rm -Rf $BUILD # clear, including CSV and configure caches

# Mozilla IDL files need special treatment
if [ "$BUILDCMD" == "make -f client.mk build" ]; then
  make -f client.mk configure
  cd $BUILD
  for f in $(find -name 'autoconf.mk'); do
    echo '-include $(DXRROOT)/plugins/moztools/myrules.mk' >> ${f/autoconf/myrules}
  done
  # clean up CSV files generated by configure
  find $objdir -name '*.csv' | xargs rm
  cd $SOURCE
fi

$SHELL -c "$BUILDCMD" 2>&1 | grep -v 'Unprocessed kind' | grep -v 'clang: warning: argument unused during compilation' || exit 1
NCSV=`find $BUILD -name "*.csv" | wc -l` && test "$NCSV" == "0" && echo Failed: No CSV files && exit 1
echo ' '

# Index
cd $CURRENTDIR
$DXRROOT/dxr-index.py -f $DXRCONFIG -t $TREE
NTBL=`echo '.tables' | sqlite3 -init /dev/stdin /$WWWROOT/$TREE/.dxr_xref/$TREE.sqlite | wc -w` && test "$NTBL" != "20" && echo Failed: Missing tables && exit 1

# Split use case
test -n $REMOTE && rsync -aHPz {$WWWROOT,$REMOTE:$WWWROOT}/$TREE-current/

