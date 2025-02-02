#!/usr/bin/ruby1.8
#######################################################################
#
# WWWWolf's Unremarkable Twitter Dump Script.
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
# This will simply take 100 most recent tweets the user has posted,
# cache them locally, and dump them out in MediaWiki format (HTML planned).
#
# Requires twitter4r RubyGem.
#
# Known issues:
#  - Will download a shitton of tweets ANYWAY
#  - Cutoff date handling may be buggy, or something
#  - The host thing isn't very useful yet (identi.ca users are SOL), but
#    this is twitter4r's fault AFAICT
#  - Error handling isn't very graceful, but it shouldn't blow up too hard
#
#######################################################################

require 'rubygems'
gem     'twitter4r', '>=0.3.0'
require 'twitter'
require 'yaml'
require 'yaml/store'
require 'cgi'

class TwitFetcher
  attr :entries
  attr :last_update
  attr :twitter_user
  attr :last_new_count
  attr :last_fetch_count

  def initialize(twitter_user, host)
    Twitter::Client.configure do |conf|
      conf.protocol = :http
      conf.host = host
      conf.port = 80

      conf.user_agent = 'WWWWolfsTwitFetcher/1.0'
      conf.application_name = 'TwitFetcher'
      conf.application_version = 'v1.0'
      conf.application_url = 'http://github.com/wwwwolf/randomscripts'
    end
    @twitter = Twitter::Client.new
    @entries = {}
    @last_update = nil
    @twitter_user = twitter_user
    @last_fetch_count = 0
  end

  def load_cache(cache_file)
    # Read in my cache and build entry hash
    if File.exists?(cache_file)
      e = YAML::load(File.open(cache_file))
      @entries = e['entries']
      @last_update = e['last_update']
      STDERR.puts "Got #{@entries.keys.length} entries from cache. Last update at #{@last_update}."
    else
      STDERR.puts "Cache file #{cache_file} not found, a new one will be created"
    end
  end

  def save_cache(cache_file)
    # Save cache.
    File.delete(cache_file) if File.exists?(cache_file)
    cache = YAML::Store.new(cache_file)
    cache.transaction do
      cache['entries'] = @entries
      cache['last_update'] = @last_update
    end
  end

  def fetch!
    # Grab new entries.
    grabbed = 0
    tl = @twitter.timeline_for(:user, :id => @twitter_user, :since => @last_update, :count => 100) do |status|
      next if @entries.has_key?(status.id)
      @entries[status.id] = {
        'id' => status.id,
        'time' => status.created_at,
        'text' => status.text
      }
      grabbed += 1
      if @last_update.nil?
        @last_update = status.created_at
      else
        @last_update = status.created_at if last_update >= status.created_at
      end
    end
    @last_fetch_count = tl.length
    @last_new_count = grabbed
  end

  def format(fmt)
    fail "Unknown format" unless [:html, :mediawiki,
                                  :html_by_date,
                                  :mediawiki_by_date].member?(fmt)
    fail "HTML is unimplemented" if fmt == :html or fmt == :html_by_date
    current_date = nil
    datehead = "something bogus not equal to nil, dammit"
    s = ""

    if fmt == :mediawiki
      s = "|-\n"
      s <<  "! Text\n"
      s << "! Time\n"
    end
    @entries.keys.sort.each do |e|
      en = @entries[e]
      datehead = en['time'].utc.strftime('%d %B %Y')
      if fmt == :mediawiki_by_date and current_date != datehead
        s << "|-\n|}\n\n" unless current_date.nil?
        s << "=== #{CGI.escapeHTML(datehead)} ===\n\n"
        s << "{| class=\"wikitable\"\n"
        s << "|-\n"
        s << "! Text\n"
        s << "! Time\n"
        current_date = datehead
      end
      s << "|-\n"
      s << "| #{CGI.escapeHTML(en['text'])}\n"
      if fmt == :mediawiki_by_date
        d = en['time'].utc.strftime('%H:%M UTC')
      else
        d = en['time'].utc.strftime('%d %B %Y, %H:%M UTC')
      end
      s << "| #{CGI.escapeHTML(d)}\n"
    end
    s << "|-\n"
    s << "|}\n" if fmt == :mediawiki_by_date
    s
  end
end
