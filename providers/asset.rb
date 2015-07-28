#
# Cookbook Name:: github
# Provider:: asset
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#

use_inline_resources

attr_reader :asset

def load_current_resource
  @asset = GithubCB::Asset.new(new_resource.repo, name: new_resource.name,
    release: new_resource.release, host: new_resource.host)
end

action :download do
  if Chef::Resource::ChefGem.instance_methods(false).include?(:compile_time)
    chef_gem "octokit" do
      compile_time true
    end
  else
    chef_gem "octokit" do
      action :nothing
    end.run_action(:install)
  end

  Chef::Log.info "github_asset[#{new_resource.name}] downloading asset"
  updated = asset.download(user: new_resource.github_user, token: new_resource.github_token,
    force: new_resource.force, path: new_resource.asset_path)
  new_resource.updated_by_last_action(updated)
end

action :delete do
  file @asset.asset_path do
    action :delete
  end

  directory new_resource.extract_to do
    recursive true
    action :delete
  end
end
