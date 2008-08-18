#!/usr/bin/ruby
# $Id$

require 'xmlrpc/client'
require 'yaml'

def pingablog(p,svc)
  puts "pinging #{p['name']}"
  if not svc.nil? then
    s = $services[svc]
    server = XMLRPC::Client.new2(s['rpcurl'])
    result = server.call("weblogUpdates.extendedPing", p['name'], p['url'], p['changes'], p['feed'])
    puts " ... on #{s['name']}: #{result['message']}"
  else
    $services.keys.each do |sv|
      s = $services[sv]
      server = XMLRPC::Client.new2(s['rpcurl'])
      result = server.call("weblogUpdates.extendedPing", p['name'], p['url'], p['changes'], p['feed'])
      puts " ... on #{s['name']}: #{result['message']}"
    end
  end
    
end

UserConf = ENV['HOME'] + "/.pingsterrc"

conffile = nil
if ENV.has_key?('PINGSTERRC')
  conffile = ENV['PINGSTERRC']
elsif File.exists?(UserConf)
  conffile = UserConf
else
  conffile = "pingster.yml"
end

fail "Can't find configuration file #{conffile}." if conffile.nil? or not File.exists?(conffile)

conf = YAML::load(File.open(conffile))
$services = conf['services']
$blogs = conf['blogs']

blog = ARGV.shift || nil
service = ARGV.shift || nil

if not blog.nil?
  pingablog($blogs[blog],service)
else
  blogs.keys.each do |blog|
    pingablog($blogs[blog],service)
  end
end
