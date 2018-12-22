#
# Cookbook Name:: github
# Library:: github_asset
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#

require 'net/http'
require 'open-uri'
require 'uri'
require 'fileutils'
require_relative 'github_errors'

module GithubCB
  class Asset
    class << self
      def asset_cache
        ::File.join(Chef::Config[:file_cache_path], "github_assets")
      end

      def asset_path(fqrn, tag, name)
        ::File.join(asset_cache, fqrn, tag, name)
      end

      def default_host
        @default_host ||= "https://github.com"
      end
    end

    attr_reader :fqrn
    attr_reader :organization
    attr_reader :repo
    attr_reader :tag_name
    attr_reader :name
    attr_reader :host

    def initialize(fqrn, options = {})
      @fqrn                = fqrn
      @organization, @repo = fqrn.split('/')
      @tag_name            = options[:release]
      @name                = options[:name]
      @host                = options[:host] ||= self.class.default_host
    end

    def asset_url(options)
      require 'octokit'

      Octokit.configure do |c|
        c.login        = options[:user]
        c.access_token = options[:token]
      end

      release = Octokit.release_for_tag(fqrn, tag_name)
      raise GithubCB::ReleaseNotFound, "release not found" if release.nil?

      asset = release[:assets].find do |asset|
        asset.name == name
      end
      raise GithubCB::AssetNotFound, "asset not found" if asset.nil?

      asset.rels[:self].href
    end

    # @param [String] filepath
    def file_checksum filepath
      Digest::SHA256.file(filepath.to_s).hexdigest
    end

    # @param [String] expected
    # @param [String] actual
    def valid_checksum? expected, actual
      expected == actual
    end

    # @option options [String] :path
    # @option options [String] :user
    # @option options [String] :token
    # @option options [Boolean] :force
    # @option options [Integer] :retries
    # @option options [Integer] :retry_delay
    # @option options [String] :checksum
    def download(options = {})
      if options[:force]
        FileUtils.rm_rf(options[:path])
      end

      return false if downloaded?(options[:path])

      proxy_uri = ENV['https_proxy'] ? URI.parse(ENV['https_proxy']) : URI('')
      proxy_uri = URI.parse(ENV['HTTPS_PROXY']) if ENV['HTTPS_PROXY']
      p_user, p_pass = proxy_uri.userinfo.split(/:/) if proxy_uri.userinfo
      uri = URI(asset_url(options))
      res = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port, p_user, p_pass).start(uri.hostname, uri.port, use_ssl: true) do |http|
        req                  = Net::HTTP::Get.new(uri.to_s)
        req['Authorization'] = "token #{options[:token]}" unless options[:token].nil?
        req['Accept']        = "application/octet-stream"

        http.request(req)
      end

      FileUtils.mkdir_p(::File.dirname(options[:path]))
      file = ::File.open(options[:path], "wb")

      open(res['location']) { |source| IO.copy_stream(source, file) }

      unless options[:checksum].nil?
        checksum = file_checksum(options[:path])
        fail GithubCB::ChecksumMismatch.new(options[:checksum], checksum) unless valid_checksum? options[:checksum], checksum
      end

      true
    rescue OpenURI::HTTPError => ex
      FileUtils.rm_rf(options[:path])
      case ex.message
      when /406 Not Acceptable/
        raise GithubCB::AuthenticationError
      else
        if options[:retries] <= 0
          raise ex
        else
          options[:retries] -= 1
          puts "Retrying Download"
          if options[:retry_delay] > 0
            sleep options[:retry_delay]
          end
          download options
        end
      end
    rescue GithubCB::ChecksumMismatch => ex
      FileUtils.rm_rf(options[:path])
      puts "Failed Checksum, Retries left #{options[:retries]}"
      if options[:retries] <= 0
        fail ex
      else
        options[:retries] -= 1
        puts "Retrying Download"
        if options[:retry_delay] > 0
          sleep options[:retry_delay]
        end
        download options
      end
    ensure
      file.close unless file.nil?
    end

    def downloaded?(path)
      ::File.exist?(path)
    end
  end
end
