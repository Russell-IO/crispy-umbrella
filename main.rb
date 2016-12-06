#!/usr/bin/env ruby
require 'diplomat'
require 'json'
require 'yaml'
require "highline"
require 'awesome_print'
require 'pp'

config_path = File.expand_path(File.join'~', ".consul-discovery.yaml")
config = YAML.load_file(config_path)

cli = HighLine.new

def consulConfigureEnvironment(uri)
  Diplomat.configure do |config|
    config.url = uri
  end
end

def getConsulDatacentres()
  Diplomat::Datacenter.get()
end

def getConsulServices(dc)
  Diplomat::Service.get_all({ :dc => dc }).marshal_dump
end

def getConsulServiceNodes(dc,service)
  nodes = { }
  Diplomat::Service.get(service, :all, { :dc => dc }).each do |node|
    nodes[node.marshal_dump[:Node]] = { :address => node.marshal_dump[:Address] }
  end
  return nodes
end

def sshToRemoteServer(node_address)
   puts "Starting SSH connection to #{node_address}"
   system("ssh #{node_address}")
end

unless ARGV[0] == nil
  env = ARGV[0]
else
  # ask user to choose and env to conncet to
  envs = config['envs'].keys
  puts 'Please select an env to connect to'
  env = cli.choose do |menu|
    menu.choices(*envs)
    menu.prompt = 'Please select an env to connect to'
  end
end

# Configure consul to connect
consul = config['envs'][env]['consul']
consulConfigureEnvironment(consul)

unless ARGV[1] == nil
  dc = ARGV[1]
else
  # ask user to choose a consul datacentre
  dcs = getConsulDatacentres()
  puts 'Please select a datacentre to connect to'
  dc = cli.choose do |menu|
    menu.prompt = 'Please select a datacentre to connect to'
    menu.choices(*dcs) 
  end
end

# Retrieve a flat array of services
#services = Array.new
#raw_services = getConsulServices(dc)
#raw_services.each do |s|
#  s[1].each do |s2|
#    services.push(s2)
#  end
#end

# Ask the user which Service they would like to connect to
#puts 'Please select a service to connect to'
#service = cli.choose do |menu|
#  menu.prompt = 'Please select a service to connect to'
#  menu.choice('All')
#  menu.choices(*services)
#end

#override hack
service = 'All'

unless service == 'All'
  nodes = getConsulServiceNodes(dc,service)
  # Ask the user which node they would like to connect to
  puts 'Please select a node to connect to'
  node = cli.choose do |menu|
    menu.prompt = 'Please select a node to connect to'
    menu.choice('All')
    menu.choices(*nodes.keys)
  end
else
  nodes = getConsulServiceNodes(dc,'puppet')
  # Ask the user which node they would like to connect to
  puts 'Please select a node to connect to'
  node = cli.choose do |menu|
    menu.prompt = 'Please select a node to connect to'
    #menu.choice('All')
    menu.choices(*nodes.keys)
  end
end

unless node == 'All'
  node_address = nodes[node][:address]
  sshToRemoteServer(node_address)
else
  nodes.each do |k,v|
    sshToRemoteServer(v[:address])
  end
end
