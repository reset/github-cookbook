#
# Cookbook Name:: github
# Resource:: deploy
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#

actions :deploy
default_action :deploy

attribute :repo, kind_of: String, name_attribute: true, required: true
attribute :version, kind_of: String, required: true
attribute :github_user, kind_of: String
attribute :github_token, kind_of: String
attribute :host, kind_of: String
attribute :path, kind_of: String, required: true
attribute :owner, kind_of: String
attribute :group, kind_of: String
attribute :shared_directories, kind_of: Array, default: [ "pids", "log" ]
attribute :force, kind_of: [TrueClass, FalseClass], default: false
attribute :retries, kind_of: Integer, default: 2
attribute :retry_delay, kind_of: Integer, default: 1
attribute :checksum, kind_of: String

attribute :configure, kind_of: Proc
attribute :before_migrate, kind_of: Proc
attribute :after_migrate, kind_of: Proc
attribute :migrate, kind_of: Proc

def deploy_path
  ::File.join(release_path, version)
end

def release_path
  ::File.join(path, "releases")
end

def shared_path
  ::File.join(path, "shared")
end
