#
# Cookbook Name:: github
# Resource:: archive
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#

actions :extract, :delete
default_action :extract

attribute :repo, kind_of: String, name_attribute: true, required: true
attribute :version, kind_of: String, default: "master"
attribute :github_user, kind_of: String
attribute :github_token, kind_of: String
attribute :host, kind_of: String
attribute :owner, kind_of: String
attribute :group, kind_of: String
attribute :extract_to, kind_of: String, required: true
attribute :force, kind_of: [TrueClass, FalseClass], default: false
attribute :retries, kind_of: Integer, default: 2
attribute :retry_delay, kind_of: Integer, default: 1
attribute :checksum, kind_of: String
