#
# Cookbook:: elasticsearch_reference
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'sysctl::apply'
include_recipe 'java'
elasticsearch_user 'elasticsearch'

#To enable bootstrap mlockall we need to give the elasticsearch server unlimited memlock.
#The proper way to do this with systemd is a config file for the service and daemon-reload.
directory '/etc/systemd/system/elasticsearch.service.d' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

file '/etc/systemd/system/elasticsearch.service.d/elasticsearch.conf' do
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOF.gsub(/^\s+/, '')
  [Service]
  LimitMEMLOCK=infinity
  EOF
  notifies :run, 'execute[reload_systemd_config]', :immediately
end

execute 'reload_systemd_config' do
  command 'systemctl daemon-reload'
  action :nothing
end

#Search for all nodes in my environment that have the same ES cluster name and push it
#into cluster_members array
es_cluster_name = node['elasticsearch']['cluster_name'] || 'elasticsearch'
query = "chef_environment:#{node.chef_environment} AND cluster_name:#{es_cluster_name}"
cluster_members = []
search(:node, query, filter_result: { 'fqdn' => ['fqdn'] }).each do |result|
  cluster_members << result['fqdn']
end

#I'm using vagrant and want the boxes to use the eth2 address to communicate
listen_ip = node['network']['interfaces']['eth2']['addresses'].keys[1].to_s

Chef::Log.warn "cluster members #{cluster_members}"

elasticsearch_config = Hash.new.tap do |es_hash|
  es_hash['bootstrap.memory_lock'] = true
  es_hash['cluster.name'] = es_cluster_name
  es_hash['discovery.zen.ping.unicast.hosts'] = cluster_members.sort
  es_hash['http.max_content_length'] = node['elasticsearch']['es_max_content_length']
  es_hash['network.host'] = listen_ip
  es_hash['node.name'] = node['hostname']
  es_hash['path.repo'] = "/var/backups"
end

elasticsearch_install 'elasticsearch' do
  type 'package' # type of install
  version node['elasticsearch']['version']
  action :install # could be :remove as well
end

elasticsearch_configure 'elasticsearch' do
  logging(action: 'INFO')
  configuration elasticsearch_config
  action :manage
end

elasticsearch_service 'elasticsearch' do
  action :configure
end
