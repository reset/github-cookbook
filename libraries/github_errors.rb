#
# Cookbook Name:: github
# Library:: github_errors
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#

module GithubCB
  class GHError < StandardError; end
  class AuthenticationError < GHError
    def initialize
      super("Unable to authenticate with Github API. Check your username/password and try again.")
    end
  end

  class ChecksumMismatch < GHError
    attr_reader :expected
    attr_reader :actual
    def initialize(expected="", actual="")
      @expected = expected
      @actual = actual
      super("expected: #{expected}, actual: #{actual}")
    end
  end

  class ReleaseNotFound < GHError; end
  class AssetNotFound < GHError; end
end
