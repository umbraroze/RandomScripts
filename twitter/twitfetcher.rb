#!/usr/bin/ruby1.8
#######################################################################
#
# WWWWolf's Unremarkable Twitter Dump Script.
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

      conf.user_agent = 'WWWWolfsRandomTwitterDumpScript/1.0'
      conf.application_name = 'WWWWolfsRandomTwitterDumpScript'
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
    fail "Unknown format" if (fmt != :html and fmt != :mediawiki)
    fail "HTML is unimplemented" if fmt == :html

    s = "|-\n"
    s <<  "! Text"
    s << "! Time"
    @entries.keys.sort.each do |e|
      # mediawiki format
      en = @entries[e]
      s << "|-"
      s << "| #{CGI.escapeHTML(en['text'])}"
      s << "| #{CGI.escapeHTML(en['time'].utc.strftime('%d %B %Y, %H:%M UTC'))}"
    end
    s << "|-"
  end
end
