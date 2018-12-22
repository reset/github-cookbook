#
# Cookbook Name:: github
# Provider:: archive
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#

use_inline_resources

attr_reader :archive

def load_current_resource
  @archive = GithubCB::Archive.new(new_resource.repo, version: new_resource.version, host: new_resource.host)
end

action :extract do
  recipe_eval do
    run_context.include_recipe "libarchive::default"
  end

  unless !new_resource.force || archive.downloaded?
    Chef::Log.info "github_archive[#{new_resource.name}] downloading archive"
    archive.download(user: new_resource.github_user, token: new_resource.github_token,
      force: new_resource.force, retries: new_resource.retries,
      retry_delay: new_resource.retry_delay, checksum: new_resource.checksum)
    new_resource.updated_by_last_action(true)
  end

  unless !new_resource.force || ::File.exist?(new_resource.extract_to)
    Chef::Log.info "github_archive[#{new_resource.name}] extracting archive to #{new_resource.extract_to}"
    archive.extract(new_resource.extract_to, force: new_resource.force,
      owner: new_resource.owner, group: new_resource.group)
    new_resource.updated_by_last_action(true)
  end
end

action :delete do
  file @archive.path do
    action :delete
  end

  directory new_resource.extract_to do
    recursive true
    action :delete
  end
end
