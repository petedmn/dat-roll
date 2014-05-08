require "open-uri"
require "rest-client"
require "crack"
require "nokogiri"
require "uri"
require 'openssl'
require "logger"
require 'builder'
require './TwitterScraper'
require './TwitterItem'
require './Tweet'
require './UserAgent'
require './RequestHandler'
require './String'
require './LogWriter'
require './config/config'

class Twitter

	attr_accessor :name_list

	def initialize
		#load conf details from the config file..		
		add_names	
		@google_scraper = GoogleTwitterScraper.new(MyConfig[:google_search_url])	
	end

	def scrape_name_list
		@name_list.each do |name|
			#name = truncate_name(name)
			url_list = @google_scraper.fetch_twitter_url_list(name)
			scrape_url_list(url_list)
		end
	end

	#This can certainly be refactored/improved... Should only be responsible for calling the Twitter Scraper, which handles the rest. 
	def scrape_url_list(url_list)
		url_list.each do |url|
			begin
			name = url.text().to_s.tap{|s| s.slice!("https://twitter.com/")}
			scraper = TwitterScraper.new(url)
		
			twitter_item = scraper.scrape_and_parse

			#the design of subverting the twitter scraper does not make sense
			
			twitter_item.parse #make sure all mandatory fields are evaluated first
			#twitter_item.fetch_tweets
			@run_file_name = "dataNow"
			twitter_item.write_to_file(name+".xml",@run_file_name)
			#get here = sucess
			sleep(20)
			
			rescue Exception => e
				#log the exception
				puts e
			end
		end
	end

	private 

	def truncate_name name
		s = name
		n = 1
		trunc = s[/(\S+\s+){#{n}}/].strip
	end

	def add_names
		@name_list = []
		File.open(MyConfig[:name_list_file], 'r') do |f|
			f.each_line do |line|
				unless line == nil
					@name_list << line
				end
			end
		end 
	end

end


class GoogleTwitterScraper	

	attr_accessor :url

	def initialize(url)
		@url = url
	end

	def fetch_twitter_url_list(name)			
		links = []		
			
		resp = RestClient.get(@url + name)
		
		doc = Nokogiri::HTML(resp)

		(1..1).each do |i|
			xpath = '/html/body/div[2]/div/ol/li['+ (i.to_s)+']/div/a/@href' #this is the url to the person's twitter profile(magic)
   			link_to_investigate = (doc.xpath(xpath))
   			links[i-1] = link_to_investigate
		 end
		 return links
	end

end

twitter = Twitter.new
twitter.scrape_name_list