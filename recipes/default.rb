#
# Cookbook:: elasticsearch_reference
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'sysctl::apply'

include_recipe 'java'

elasticsearch_user 'elasticsearch'

directory '/var/run/elasticsearch' do
  action :create
  recursive true
  owner 'elasticsearch'
  group 'elasticsearch'
end

es_cluster_name = node['elasticsearch']['cluster_name'] || 'elasticsearch'
query = "chef_environment:#{node.chef_environment} AND cluster_name:#{es_cluster_name}"
Chef::Log.warn "query: #{query}"
cluster_members = []
search(:node, query, filter_result: { 'fqdn' => ['fqdn'] }).each do |result|
  cluster_members << result['fqdn']
end
#I'm using vagrant and want the boxes to use the eht2 address to communicate
listen_ip = node['network']['interfaces']['eth2']['addresses'].keys[1].to_s

Chef::Log.warn "cluster members #{cluster_members}"

elasticsearch_config = Hash.new.tap do |es_hash|
  es_hash['cluster.name'] = es_cluster_name
  es_hash['node.name'] = node['hostname']
  es_hash['network.host'] = listen_ip
  if node['aws'] && node['aws'].has_key?('region')
    es_hash['discovery.type'] = 'ec2'
    es_hash['cloud.aws.region'] = node['aws']['region']
  else
    es_hash['discovery.zen.ping.unicast.hosts'] = cluster_members.sort
  end
  es_hash['http.max_content_length'] = node['elasticsearch']['es_max_content_length']
end

elasticsearch_install 'elasticsearch' do
  type 'package' # type of install
  version node['elasticsearch']['version']
  action :install # could be :remove as well
end

half_system_ram = (node['memory']['total'].to_i * 0.5).floor / 1024

elasticsearch_configure 'elasticsearch' do
  logging(action: 'INFO')

  jvm_options %w(
              -Dlog4j2.disable.jmx=true
              -XX:+UseParNewGC
              -XX:+UseConcMarkSweepGC
              -XX:CMSInitiatingOccupancyFraction=75
              -XX:+UseCMSInitiatingOccupancyOnly
              -XX:+HeapDumpOnOutOfMemoryError
              -XX:+PrintGCDetails
              -Xss512k
  )

  configuration elasticsearch_config
  action :manage
end

execute 'install discovery-ec2 plugin' do
  command "sudo /opt/elasticsearch-#{node['elasticsearch']['version']}/bin/elasticsearch-plugin install discovery-ec2"
  not_if { ::Dir.exist?("/opt/elasticsearch-#{node['elasticsearch']['version']}/plugins/discovery-ec2") }
  only_if { node['aws'] }
end

elasticsearch_service 'elasticsearch' do
  action :configure
end

