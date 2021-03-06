from dxr.testing import DxrInstanceTestCaseMakeFirst

from nose.tools import ok_, eq_


class MercurialTests(DxrInstanceTestCaseMakeFirst):
    """Test our Mercurial integration, both core and omniglot."""

    def test_diff_file1(self):
        """Make sure the diff link goes to the first after-initial commit."""
        response = self.client().get('/code/source/ChangedInCommit1')
        ok_('/diff/2e86c4e11a82f3ec17867468e499e85ec3cbf441/ChangedInCommit1" title="Diff" class="diff icon">Diff</a>' in response.data)

    def test_diff_file2(self):
        """Make sure the diff link goes to the second after-initial commit."""
        response = self.client().get('/code/source/ChangedInCommit2')
        ok_('/diff/cd18424a4dab95361e25e86398e557d3d889e2c8/ChangedInCommit2" title="Diff" class="diff icon">Diff</a>' in response.data)

    def test_diff_file3(self):
        """Make sure the diff link goes to the third after-initial commit."""
        response = self.client().get('/code/source/Filename With Space')
        ok_('/diff/1be3fc90ef0104cf186fac7bc0bbfea17ba6ebdc/Filename With Space" title="Diff" class="diff icon">Diff</a>' in response.data)

    def test_blame(self):
        """Make sure the blame link goes to the right place."""
        response = self.client().get('/code/source/ChangedInCommit1')
        ok_('/annotate/84798105c9ab5897f8c7d630d133d9003b44a62f/ChangedInCommit1" title="Blame" class="blame icon">Blame</a>' in response.data)

    def test_raw(self):
        """Make sure the raw link goes to the right place."""
        response = self.client().get('/code/source/ChangedInCommit2')
        ok_('/raw-file/84798105c9ab5897f8c7d630d133d9003b44a62f/ChangedInCommit2" title="Raw" class="raw icon">Raw</a>' in response.data)

    def test_log(self):
        """Make sure the log link goes to the right place."""
        response = self.client().get('/code/source/Filename With Space')
        ok_('/filelog/84798105c9ab5897f8c7d630d133d9003b44a62f/Filename With Space" title="Log" class="log icon">Log</a>' in response.data)

    def test_permalink(self):
        """Make sure the permalink exists, and that the response is ok."""
        # Flask's url_for will escape the url, so spaces become %20
        response = self.client().get('/code/source/Colon: name')
        ok_('/rev/84798105c9ab5897f8c7d630d133d9003b44a62f/Colon:%20name" title="Permalink" class="permalink icon">Permalink</a>' in response.data)
        response = self.client().get('/code/rev/84798105c9ab5897f8c7d630d133d9003b44a62f/Colon: name')
        eq_(response.status_code, 200)

    def test_mdates(self):
        """Make sure that modified dates listed in browse view are dates of
        the last commit to the file.
        """
        response = self.client().get('/code/source/').data
        ok_('<time>2014 Nov 06 19:11</time>' in response)
        ok_('<time>2014 Oct 30 20:10</time>' in response)
