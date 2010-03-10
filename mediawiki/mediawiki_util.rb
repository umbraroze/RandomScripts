#!/usr/bin/ruby1.8
#######################################################################
#
# WWWWolf's random wrapper over MediaWikiAPIClient.
# Copyright (C) 2010  Urpo Lankinen
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################
#
# This is just boring code to help making MediaWiki apps easier.
# MediaWikiAPIClient is pretty basic.
#
#######################################################################

require 'rubygems'
gem     'mediawikiapi_client', '>= 0.2'
require 'mediawikiapi_client'
require 'yaml'
require 'net/http'
require 'uri'
require 'parsedate'

class MediaWikiClient
  attr :mw
  attr :api_root
  def initialize(url,api_root)
    @mw = MediaWikiAPIClient.new(url,:api_path => api_root)
    @api_root = api_root
  end
  def get_namespaces
    YAML.load(mw.query(:meta => :siteinfo,
                       :siprop => :namespaces,
                       :format => :yaml))['query']['namespaces']
  end
  def get_allpages(ns_id,prefix)
    imagelist = nil
    parms = { :list => :allpages,
      :apnamespace => ns_id,
      :aplimit => 500,
      :format => :yaml }
    parms[:apprefix] = prefix unless prefix.nil?      
    imagelist = YAML.load(mw.query(parms))
    r = []
    imagelist['query']['allpages'].each do |i|
      r.push(i['title'].chomp)
    end
    r
  end
  def get_image_info(name,props)
    p = (props.nil? ? "timestamp|user" : props)
    YAML.load(mw.query(:prop => :imageinfo,
                       :titles => name,
                       :iiprop => props,
                       :iilimit => 500,
                       :format => :yaml))['query']['pages']
  end
  def fetch_image_to(url,target_file,timestamp)
    u = URI.parse(url)
    # Check because the old version sometimes feeds us relative paths.
    if(u.relative?)
      u = URI.parse(@api_root) # Take the MW host.
      u.path = url # Replace the path part with the one we were fed.
    end
    res = Net::HTTP.start(u.host, u.port) do |http|
      http.get(u.path)
    end

    return res.code if res.code != '200' # Bail out on error
    File.open(target_file,"w") do |f|
      f.write res.body
    end
    return res.code if timestamp.nil? # Skip the rest unless we want timestamps
    # NB: Timestamp is *sometimes* returned in ISO format, sometimes
    # parsed automagically by YAML parser. (Logic is the developer's goal.
    # Those developers may or may not be the ones developing these things.)
    # Hence, .to_s added so chomping should work always.
    ts = Time.utc(*ParseDate.parsedate(timestamp.to_s.chomp))
    File.utime(Time.now,ts,target_file)
    res.code
  end
end

