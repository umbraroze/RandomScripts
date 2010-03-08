#!/usr/bin/ruby1.8
#######################################################################
#
# WWWWolf's Puny MediaWiki Client
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
# This is a horribly limited and hacky MediaWiki client. Do not use it.
#
# Known issues:
#  - It's puny.
#  - It can blow up.
#  - It won't fetch everything, probably.
#
#######################################################################

require 'yaml'
require 'net/http'
require 'uri'
require 'cgi'
require 'parsedate'

class MediaWikiClient
  attr :api_root
  class WebRequest
    USER_AGENT = 'PunyMediaWikiClient/0.0'
    attr_reader :url
    attr :cookie
    attr :body
    attr :content_type
    attr :code
    def setup_req(url)
      @url = URI.parse(url)
      @req = Net::HTTP::Get.new(@url.to_s)
      @req['User-Agent'] = USER_AGENT
    end
    def get_url(url)
      setup_req(url)
      res = Net::HTTP.start(@url.host, @url.port) { |http|
        http.request(@req)
      }
      @cookie = res['Set-Cookie']
      @body = res.body
      @content_type = res.content_type
      @code = res.code
      @body
    end
    def initialize
    end
    def to_s
      return "Cookie: #{cookie}\n\nBody:\n#{body}\n"
    end
  end
  def initialize(api_root)
    @api_root = api_root
    #login(site,user,password)
  end
  def get_namespaces
    r = perform_query('action=query&meta=siteinfo&siprop=namespaces')
    r['query']['namespaces']
  end
  def get_allpages(ns_id,prefix)
    prefix = (prefix.nil? ? "" : "&apprefix=#{CGI.escape(prefix)}")
    imagelist = perform_query("action=query&list=allpages&apnamespace=#{ns_id}&aplimit=500#{prefix}")
    r = []
    imagelist['query']['allpages'].each do |i|
      r.push(i['title'].chomp)
    end
    r
  end
  def get_image_info(name,props)
    p = (props.nil? ? "timestamp|user" : props)
    r = perform_query("action=query&prop=imageinfo&titles=#{CGI.escape(name)}&iiprop=#{CGI.escape(p)}&iilimit=500")
    r['query']['pages']
  end
  def fetch_image_to(url,target_file,timestamp)
    # Check because the old version sometimes feeds us relative paths.
    if(URI.parse(url).relative?)
      h = URI.parse(@api_root)
      h.path = url # Replace the path part with the one we were fed.
      url = h.to_s
    end
    req = WebRequest.new()
    res = req.get_url(url.chomp)
    return req.code if req.code != '200' # Bail out on error
    File.open(target_file,"w") do |f|
      f.write res
    end
    return req.code if timestamp.nil? # Skip the rest unless we want timestamps
    # NB: Timestamp is *sometimes* returned in ISO format, sometimes
    # parsed automagically by YAML parser. (Logic is the developer's goal.
    # Those developers may or may not be the ones developing these things.)
    # Hence, .to_s added so chomping should work always.
    ts = Time.utc(*ParseDate.parsedate(timestamp.to_s.chomp))
    File.utime(Time.now,ts,target_file)
    req.code
  end
  private
  def perform_query(query)
    req = WebRequest.new()
    res = req.get_url("#{@api_root}?#{query}&format=yaml")
    if req.content_type != 'application/yaml'
      fail "WTF? #{req.content_type} instead of YAML?"
    end
    r = YAML::load(res)
    if r.has_key?('error')
      fail "MediaWiki API reports following error: #{r['error']}"
    end
    r
  end
end

