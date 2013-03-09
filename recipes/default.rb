#
# Cookbook Name:: rails-bootstrap
# Recipe:: default
#
# Copyright 2013, 119 Labs LLC
#
# See license.txt for details
#
class Chef::Recipe
    # mix in recipe helpers
    include Chef::RubyBuild::RecipeHelpers
end

app_dir = node['rails-lastmile']['app_dir']
listen = node['rails-lastmile']['listen'] || "0.0.0.0:8080"
worker_processes=node['rails-lastmile']['worker_processes'] || 2
include_recipe "rails-lastmile::setup"

include_recipe "unicorn"

directory "/var/run/unicorn" do
  owner "root"
  group "root"
  mode "777"
  action :create
end

file "/var/run/unicorn/master.pid" do
  owner "root"
  group "root"
  mode "666"
  action :create_if_missing
end

file "/var/log/unicorn.log" do
  owner "root"
  group "root"
  mode "666"
  action :create_if_missing
end

template "/etc/unicorn.cfg" do
  owner "root"
  group "root"
  mode "644"
  source "unicorn.erb"
  variables( :app_dir => app_dir)
end

rvm_shell "run-rails" do
  ruby_string node['rails-lastmile']['ruby_version']
  cwd app_dir
  if node['rails-lastmile']['reset_db']
    code <<-EOT1
      bundle install
      bundle exec rake db:drop
      bundle exec rake db:setup
      ps -p `cat /var/run/unicorn/master.pid` &>/dev/null || bundle exec unicorn -c /etc/unicorn.cfg -D --env #{node['rails-lastmile']['environment']}
    EOT1
  else
    code <<-EOT2
      bundle install
      bundle exec rake db:migrate
      ps -p `cat /var/run/unicorn/master.pid` &>/dev/null || bundle exec unicorn -c /etc/unicorn.cfg -D --env #{node['rails-lastmile']['environment']}
    EOT2
  end
end


service "unicorn"
