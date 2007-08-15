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
		realurl = $1.gsub(/ /,'%20')
		STDERR.puts "[Song  ] Grabbed URL: #{realurl}"
		return realurl
	end
	def get(url)
		STDERR.puts "[Main  ] Going to get the index"
		parse_index_page(url)
		STDERR.puts "[Main  ] Going to get the songs now"
		@song_info_pages.each do |p|
			s = rand(11)+1
			STDERR.puts "[Main  ] Throttling for #{s} seconds"
			sleep s
			url = parse_song_page(p)
			puts "wget --referer=#{p} '#{url}'"
		end
	end
end

indexurl = ARGV.shift
fail "Usage: ruby gh_ffshrine_getalbum.rb http://gh.ffshrine.org/soundtracks/123456" if indexurl.nil?
ghgm = GHGetMonster.new
ghgm.get(indexurl)
