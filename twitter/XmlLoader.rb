require 'nokogiri'
require 'crack'
require 'json'
require_relative './Tweet'


class TweetLoader
	def initialize(file_name)
		puts "tweet loader.new"+file_name
		@file = File.open(file_name)
	end

	def load_tweets
		@tweets = Array.new
		content = @file.read
		xpath = "//tweet"
		xml = Nokogiri::XML(content)
		xml.xpath(xpath).each do |tweet|
			tweet_id = tweet.xpath("@tweet_id").to_s			
			retweets = tweet.xpath("./retweet_count/text()").to_s
			favs = tweet.xpath("./favourite_count/text()").to_s
			content = tweet.xpath("./tweet_content/text()").to_s			
	    dt = tweet.xpath("./date_time/text()")
			t = Tweet.new
			t.set_content content
			t.set_retweet_count retweets
			t.set_favourite_count favs
			t.set_date_time dt
			@tweets << t
		end	
	end

	def get_tweets
		return @tweets
	end

end
