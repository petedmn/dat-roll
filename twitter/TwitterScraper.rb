require "open-uri"
require "rest-client"
require "crack"
require "nokogiri"
require "uri"
require 'openssl'
require "logger"
require 'builder'
require './TwitterItem'
require './Tweet'
require './UserAgent'
require './RequestHandler'
require './String'
require './LogWriter'

#the twitter scraper will be passed a page, and scrape it.
#handles twitter-specific networking issues such as infinite scroll
class TwitterScraper

	def initialize(url)
		#first we need to figure out the twitter profile name of the person we are scraping...
		@name = url.text().to_s.tap{|s| s.slice!("https://twitter.com/")}
		puts "NAME:"+@name		
		@url = URI.escape(url.to_s)	
		@page = []
		@count = 0
		#switch user agents for every single new scraper.
		@userAgent = UserAgent.new
	end

	#first loads the base page, then continually
	#calls twitters asyncrhonous functions in order to load past the 
	#infinite scrolling problem
	def scrape
	begin
		@document = fetch_page
		twitterItem = TwitterItem.new(@document,@resp,@url,@name,@userAgent)
		tweets = twitterItem.fetch_tweets	
		@has_more = true
		while @has_more == true and @count < 500
			puts @count
			@count = @count + 1
			@has_more = fetch_more_tweets(twitterItem,tweets)
			sleep(5) #we should wait between requests or else shit gets bad	
		end	
	rescue Exception => e
		LogWriter.error(e)
		twitterItem.write_to_file(@name,"fails")
		throw e# we still want to throw the exception at this level!
	end
		return twitterItem
	end

	#fetch more tweets will load more tweets based on the 
	#given twitter item, and its tweet set. Returns true if there are more tweets to
	#fetch
	def fetch_more_tweets(twitterItem,tweets)
		LogWriter.test("Time taken to fetch extra tweets...START")
		###
		#make the async request to get more data
		###
		base_request_url = "https://twitter.com/i/profiles/show/"
		profile_name = @name
		remainder = "/timeline/with_replies?include_available_features=1&include_entities=1&max_id="		
		max_tweet_id = twitterItem.max_tweet_id
		#puts "max ID" + max_tweet_id.to_s
		request_url =URI.escape((base_request_url+profile_name+remainder+(max_tweet_id.to_s)).to_s)		
		response = fetch_page(request_url)
		LogWriter.test("Time taken to fetch extra tweets...END")

		#puts "fetching more tweets"+request_url		
		json = parse_response(response)

		#the twitter item then parses this response
		@has_more = twitterItem.fetch_extra_tweets(json)
		
		return @has_more
	end

	#this is used to fetch pages. 
	def fetch_page	
			@resp = RestClient.get(@url,:user_agent => @userAgent.get_user_agent.to_s)
			@document = Nokogiri::HTML(@resp)
			return @document
	end

	#fetch page for the given url
	#503 errors are being thrown from here currently. May be due to detection of same user agent. 
	#If exception thrown, get a new user agent, wait a bit, then try again.
	def fetch_page(url,fail_count=0)
			begin
				resp = RestClient.get(url,:user_agent => @userAgent.get_user_agent.to_s)
				return resp
			rescue Exception => e
				if failed_count > 3 #if we have failed more than 3 times, give up
					throw e
				end
				#exception thrown trying to fetch the resource... Try again with a different user agent.
					@userAgent = UserAgent.new
					sleeps(20) #token gesture - wait a little bit, see if the issue is solved.
					fetch_page(url,failed_count + 1)
			end
	end

	def parse_response(response)
		begin
			json = Crack::JSON.parse(response)	
		rescue Crack::ParseError => e
			puts response
			LogWriter.debug(response)
			#the response is being difficult/malformed JSON response
			return	manual_parse_response(response)
		end
	end

	def manual_parse_response(response)
		puts "manual parsing of response"
	end

end

