#
# Cookbook Name:: github
# Library:: github_archive
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#

require 'open-uri'
require 'uri'
require 'fileutils'
require_relative 'github_errors'

module GithubCB
  class Archive
    class << self
      def default_host
        @default_host ||= "https://github.com"
      end
    end

    attr_reader :fqrn
    attr_reader :organization
    attr_reader :repo
    attr_reader :version
    attr_reader :host

    def initialize(fqrn, options = {})
      @fqrn                = fqrn
      @organization, @repo = fqrn.split('/')
      @version             = options[:version] ||= "master"
      @host                = options[:host] ||= self.class.default_host
    end

    # @option options [String] :user
    # @option options [String] :token
    # @option options [Boolean] :force
    def download(options = {})
      if options[:force]
        FileUtils.rm_rf(local_archive_path)
      end

      FileUtils.mkdir_p(File.dirname(local_archive_path))
      file = ::File.open(local_archive_path, "wb")

      open(download_uri, http_basic_authentication: [options[:user], options[:token]]) do |source|
        IO.copy_stream(source, file)
      end
    rescue OpenURI::HTTPError => ex
      case ex.message
      when /406 Not Acceptable/
        raise GithubCB::AuthenticationError
      else
        raise ex
      end
    ensure
      file.close unless file.nil?
    end

    def downloaded?
      File.exist?(local_archive_path)
    end

    # @param [String] target
    #
    # @option options [String] :owner
    # @option options [String] :group
    def extract(run_context, target, options = {})

      if options[:force]
        FileUtils.rm_rf(target)
      end

      archive = Chef::Resource::LibarchiveFile.new("#{repo}-#{version}", run_context)
      archive.path(local_archive_path)
      archive.owner(options[:owner])
      archive.group(options[:group])
      archive.extract_to(target)
      run_context.resource_collection.insert(archive)
    end

    def local_archive_path
      File.join(archive_cache_path, "#{repo}-#{version}.tar.gz")
    end
    alias_method :path, :local_archive_path

    private

      def archive_cache_path
        File.join(Chef::Config[:file_cache_path], "github_deploy", "archives")
      end

      def download_uri
        uri      = URI.parse(host)
        uri.path = "/#{fqrn}/archive/#{URI.encode(version)}.tar.gz"
        uri
      end
  end
end
