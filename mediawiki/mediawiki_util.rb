#!/usr/bin/ruby1.8
#######################################################################
#
# WWWWolf's random wrapper over MediaWikiAPIClient.
#
#######################################################################
#
# Copyright (c) 2010 Urpo Lankinen
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
                       :iihistory => true,
                       :format => :yaml))['query']['pages']
  end
  def fetch_image_to(url,target_file,timestamp)
    u = URI.parse(url.chomp)
    # Check because the old version sometimes feeds us relative paths.
    if(u.relative?)
      u = URI.parse(@api_root) # Take the MW host.
      u.path = url.chomp # Replace the path part with the one we were fed.
    end
    #puts ">>> Fetching #{u.to_s}"
    res = Net::HTTP.start(u.host, u.port) do |http|
      http.get(u.path)
    end

    return res.code if res.code != '200' # Bail out on error
    File.open(target_file,"w") do |f|
      f.write res.body
    end
    return res.code if timestamp.nil? # Skip the rest unless we want timestamps

    File.utime(Time.now,MediaWikiClient.parse_date(timestamp),target_file)
    res.code
  end
  def MediaWikiClient.parse_date(datestr)
    # NB: Timestamp is *sometimes* returned in ISO format, sometimes
    # parsed automagically by YAML parser. (Logic is the developer's goal.
    # Those developers may or may not be the ones developing these things.)
    # Hence, .to_s added so chomping should work always.
    Time.utc(*ParseDate.parsedate(datestr.to_s.chomp))
  end
end
