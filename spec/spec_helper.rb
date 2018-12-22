require 'rubygems'
require 'bundler'
require 'rspec'
require 'spork'
require 'chef'
require 'rspec/its'

Spork.prefork do
  Dir[File.join(File.expand_path("../../spec/support/**/*.rb", __FILE__))].each { |f| require f }

  RSpec.configure do |config|
    config.expect_with :rspec do |c|
      c.syntax = :expect
    end

    config.mock_with :rspec
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true

    config.before(:each) do
      Chef::Config[:file_cache_path] = File.join(tmp_path, "chef_cache")
      FileUtils.rm_rf(tmp_path)
      FileUtils.mkdir_p(tmp_path)
      FileUtils.mkdir_p(Chef::Config[:file_cache_path])
    end
  end

  def tmp_path
    File.expand_path(File.join(File.dirname(__FILE__),"../tmp"))
  end
end

Spork.each_run do
  Dir["#{File.expand_path('..', File.dirname(__FILE__))}/libraries/*.rb"].sort.each do |path|
    require_relative "../libraries/#{File.basename(path, '.rb')}"
  end
end
