require 'rest-client'
require 'nokogiri'
require 'crack'
require_relative './Tweet'
require_relative './UserAgent'

#helper class to deal with mistakes around saving date time values in the past.
class TimeAnalysis

	def initialize(file_name)
		@file = File.open(file_name)
		@file_name = file_name
	end

	def execute
		@tweets = Array.new
		xml_string = @file.read
		xml = Nokogiri::XML(xml_string)
		xpath = ("//tweet")
		xml.xpath(xpath).each do |tweet|
			tweet_id = tweet.xpath("@tweet_id").to_s			
			retweets = tweet.xpath("./retweet_count/text()").to_s
			favs = tweet.xpath("./favourite_count/text()").to_s
			content = tweet.xpath("./tweet_content/text()").to_s			
	    dt=	get_date_time(tweet_id,retweets,favs,content)
			t = Tweet.new
			t.set_content content
			t.set_retweet_count retweets
			t.set_favourite_count favs
			t.set_date_time dt
			@tweets << t
		end	
	end

	def get_date_time(tweet_id,retweets,favs,content)
		url = "https://twitter.com/i/expanded/batch/"+tweet_id+"?facepile_max=7&include%5B%5D=social_proof&include%5B%5D=ancestors&include%5B%5D=descendants"
		response = get_url(url)
		tweet = Tweet.new
		tweet.fetch_date_time(response)
	end

	def save
		xml = construct_xml
		file = File.open(@file_name+"_dt.xml","w")
		file.write(xml)
	end

	def get_tweets
		return @tweets
	end

	def construct_xml
		puts 'building xml'		
		builder = Nokogiri::XML::Builder.new do |xml|
		xml.profile {
			xml.tweets{
				@tweets.each do |t|
					if t.is_a? Tweet
					xml.tweet(:tweet_id => t.get_id){						
        				xml.tweet_content_  t.get_content
        				xml.retweet_count_     t.get_retweet_count
        				xml.favourite_count_ t.get_favourite_count
								xml.date_time_ t.get_date_time
        		}	
        		end
			end
			}				
		}
		end	
		return builder.to_xml
	end

	def get_url(url)
		user_agent = UserAgent.new
		response = RestClient.get(url,:user_agent => user_agent.get_user_agent.to_s)
	end

end

#if ARGV[0]
#	file_name = ARGV[0]
#	RestClient.proxy = ENV['http_proxy']
#	time = TimeAnalysis.new(file_name)
#	time.execute
#else
# exit "please input a file to analyse time values for!"
#end
