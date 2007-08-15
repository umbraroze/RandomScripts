#!/usr/bin/ruby
# Oh, so GH thinks it's clever, eh? Each file's address is stored in separate
# pages so they just make the leechers to spend more CPU power and bandwith
# getting the pages. Oh well, have it your way... Unwrapping my new toy:
# hpricot.

begin
	require 'rubygems'
rescue LoadError # We assume the rest of the classes are usable without rubygems
end
require 'cgi'
require 'hpricot'
require 'net/http'
require 'uri'

class GHGetMonster
	attr :index_url
	attr :song_info_pages
	class WebRequest
		USER_AGENT = 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.4) Gecko/20070508 Iceweasel/2.0.0.4 (Debian-2.0.0.4-1)'
		attr_reader :url
		attr :body
		def setup_req(url)
			@url = URI.parse(url)
			@req = Net::HTTP::Get.new(@url.path)
			@req['User-Agent'] = USER_AGENT
		end
		def get_url(url,referer=nil)
			STDERR.puts "[WebReq] Getting #{url}"
			setup_req(url)
			unless referer.nil?
				STDERR.puts "         With referer #{referer}"
				@req['Referer'] = referer
			end
			res = Net::HTTP.start(@url.host, @url.port) { |http|
				http.request(@req)
			}
			@body = res.body
			STDERR.puts "[WebReq] Done (#{@body.length} bytes)"
		end
	end
	def parse_index_page(url)
		STDERR.puts "[Index ] Getting index page"
		@index_url = url
		r = WebRequest.new
		r.get_url(@index_url)
		doc = Hpricot(r.body)
		@song_info_pages = doc.search("//a[@href]").collect { |l|
			l.attributes['href']
		}.find_all { |l|
			l =~ /^\/song\//
		}.collect { |l|
			"http://gh.ffshrine.org#{l}"
		}
		STDERR.puts "[Index ] Index page done: #{@song_info_pages.length} links found"
	end
	def parse_song_page(url)
		STDERR.puts "[Song  ] Grabbing song link for #{url}"
		r = WebRequest.new
		r.get_url(url,@index_url)
		# And a hint for GH folks: If you hide the URL in a script element,
		# it makes it only easier to find...
		doc = Hpricot(r.body)
		code = CGI::unescape((doc/"script").find_all { |s|
			s.to_s =~ /var data =/
		}.to_s)
		code =~ /\"(http:\/\/[^\"]+)\"/
		realurl = $1
		unless realurl.nil?
			realurl.gsub!(/ /,'%20')
			realurl.gsub!(/,/,'%2C')
			STDERR.puts "[Song  ] Grabbed URL: #{realurl}"
		else
			STDERR.puts "[Song  ] ...hmm, can't get it."
		end
		return realurl
	end
	def get(url)
		STDERR.puts "[Main  ] Going to get the index"
		parse_index_page(url)
		if @song_info_pages.length == 0
			STDERR.puts "[Main  ] Well, that doesn't bode well. Better quit while we're still winning."
			exit
		end
		STDERR.puts "[Main  ] Going to get the songs now"
		@song_info_pages.each do |p|
			url = nil
			site_dead = false
			while url.nil?
				s = (rand(10)+1)
				if site_dead
					s += (rand(20)+1)
				end
				STDERR.puts "[Main  ] Throttling for #{s} seconds"
				sleep s
				url = parse_song_page(p)
				if url.nil?
					STDERR.puts "[NOTE  ] Couldn't grab the URL. (Site dying?) Retrying..."
					site_dead = true
				end
			end
			puts "wget --referer=#{p} '#{url}'"
			STDOUT.flush
		end
	end
end

indexurl = ARGV.shift
fail "Usage: ruby gh_ffshrine_getalbum.rb http://gh.ffshrine.org/soundtracks/123456" if indexurl.nil?
ghgm = GHGetMonster.new
ghgm.get(indexurl)
