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

def consulConfigureEcosystem(uri)
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
  ecosystem = ARGV[0]
else
  # ask user to choose and env to conncet to
  ecosystems = config['ecosystems'].keys
  puts 'Please select an ecosystem to connect to'
  ecosystem = cli.choose do |menu|
    menu.choices(*ecosystems)
    menu.prompt = 'Please select an ecosystem to connect to'
  end
end

# Configure consul to connect
consul = config['ecosystems'][ecosystem]['consul']
consulConfigureEcosystem(consul)

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

nodes = getConsulServiceNodes(dc,'puppet')
# Ask the user which node they would like to connect to
puts 'Please select a node to connect to'
node = cli.choose do |menu|
  menu.prompt = 'Please select a node to connect to'
  #menu.choice('All')
  menu.choices(*nodes.keys)
end

unless node == 'All'
  node_address = nodes[node][:address]
  sshToRemoteServer(node_address)
else
  nodes.each do |k,v|
    sshToRemoteServer(v[:address])
  end
end
