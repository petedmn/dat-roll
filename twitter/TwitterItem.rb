require "open-uri"
require "rest-client"
require "crack"
require "nokogiri"
require "uri"
require 'openssl'
require "logger"
require 'builder'
require './TwitterScraper'
require './Tweet'
require './UserAgent'
require './RequestHandler'
require './String'
require 'thread'
require 'work_queue'


#a Twitter Item takes a twitter page as an xml document
#and turns it into structured, useful data.
#a single Twitter Item corresponds to all the data relevant to ONE individual's profile.
class TwitterItem

	def initialize(content,raw,url,name,user_agent)
		@name = name
		@url = url
		@raw = raw
		@content = content
		@tweets = Array.new
		@number_of_tweets = nil
		@number_following = nil
		@number_followers = nil
		@user_agent = user_agent
		@real_name = nil
	end

	#parse the content of a tweet and container node t, saving this to the given
	#tweet object
	def parse_tweet_content (tweet, t)
		start_time = Time.now
		begin
		tweet_id = t.xpath("@data-item-id").text().to_s.strip
		@max_tweet_id = tweet_id
		tweet.set_id(tweet_id)
		#puts tweet_id
		tweet_content = t.xpath("./div/div/p/text()").to_s.strip
		#puts tweet_content
		tweet.set_content(tweet_content)
		tweet.set_raw_content(t)

	rescue Exception => e
		throw e
	end	
		return tweet
	end	

	#tweet parser for the JSON response for infinite scrolling.
	#add these tweets to the tweet array for the page we are parsing
	def	fetch_extra_tweets(json)
		begin
		#put the brakes on. Wait 10 seconds between requests.
		sleep(10)
		#we have a hash of values to deal with....
		#puts "parsing the extra tweets"	
		#puts json["max_id"]
		@max_tweet_id = json["max_id"]
		#puts "new max id"+@max_tweet_id
		@has_more = json["has_more_items"]
		content_to_parse = json["items_html"]

 		container_node_set = Nokogiri::HTML(content_to_parse)	
 		#Multi-Threading! 
 		wq = WorkQueue.new 15,20

 		tweet_set = Array.new
 		container_node_set.xpath("html/body/li").each do |t|
 			begin
 			wq.enqueue_b do
 			tweet = Tweet.new(@name,get_real_name)
 			tweet.parse_tweet_content(t)
 			#tweet.set_raw_content(t)
 			if(tweet.is_of_page_owner == true)
 				@tweets << tweet
 			end
 			end		
 			rescue Exception => e
 				puts "Exception in thread...#{wb}, #{e}"#throw away exceptions in sub threads.
 			end	
 		end		
 		wq.join
 		wq.kill #kill threads 
 		#we have a number of tweets that can then be parsed by out
 		#thread pool...


		return @has_more
	rescue Exception => e
		puts "fatal exception parsing set of tweets.."
	end
	end

	def parse_tweet(tweet)
		tweet.parse_tweet_content
	end

	#do the fetching and saving of the tweet data itself. 
	def parse_individual_tweets
		tweet_fetcher = TweetFetcher.new(@tweets)
		tweet_fetcher.fetch_all_content
	end

	def max_tweet_id
		#puts "max tweet id" + @max_tweet_id
		return @max_tweet_id
	end

	def get_tweets
		return @tweets
	end

	#write the current twitter item to a file! (writes the whole thing at present! Should move to changed-based)
	#TODO moved to change based file storage, might be slower overall though?
	def write_to_file(file_name, directory_name)
		start_time = Time.now
		begin
			Dir::mkdir(directory_name)
		rescue Exception=> e
		end
		puts directory_name+"/"+file_name
		file = File.open(directory_name+"/"+file_name,"w")
		xml = construct_xml
		file.write(xml)		
		file.close		
		end_time = Time.now
		time_taken = (end_time - start_time).to_s

	end	

	def construct_xml
		puts 'building xml'		
		builder = Nokogiri::XML::Builder.new do |xml|
		xml.profile {
			xml.key_values{ 
				xml.number_followers_ @number_followers
				xml.number_tweets_ @number_of_tweets
				xml.number_following_ @number_following
			}
			xml.tweets{
				@tweets.each do |t|
					if t.is_a? Tweet
					xml.tweet(:tweet_id => t.get_id){						
        				xml.tweet_content_  t.get_content
        				xml.retweet_count_     t.get_retweet_count
        				xml.favourite_count_ t.get_favourite_count
        				xml.retweet_names{
	        				retweet_names = t.get_retweeter_list
	        				unless retweet_names == nil then
	        				retweet_names.each do |name|
	        					xml.name_ name
	        				end
	        			end
        				}
        			
					xml.date_time_ t.get_date_time
        		}	
        		end
			end
			}				
		}
		end	
		return builder.to_xml
	end

	#write the 
	def write_to_file_response(file_name,directory_name)
		begin
			Dir::mkdir(directory_name)
		rescue Exception=>e
		end

		file = File.open(directory_name+"/"+file_name,"w")
		file.write(@raw.to_s)
		file.close
	end

	#return the number of tweets fetched so far for this twitter item
	#this is returned as a string.. as it is currently only used for logging purposes!
	def num_fetched
		return @tweets.size.to_s
	end

		#method to automatically evaluate the various fields e.g. num tweets, following,followers
	def parse
		get_num_tweets
		get_num_following
		get_num_followers
	end

	def get_real_name
		if @real_name == nil then
			node_set = @content.xpath('//*[@id="page-container"]/div[2]/div[1]/div[2]/h1/span/text()')
			@real_name = node_set.to_s
			return @real_name
		else
			return @real_name
		end
	end

	def get_num_tweets
		if @number_of_tweets == nil then
			number_of_tweets_node_set = @content.xpath("(//*[@data-element-term='tweet_stats'])[1]")
			node = number_of_tweets_node_set.first
			@number_of_tweets = node.inner_text()
			return @number_of_tweets
		else
			return @number_of_tweets
		end
	end

	def get_num_following
		if @number_following == nil then
			number_following_node_set = @content.xpath("(//*[@data-element-term='following_stats'])[1]")
 			node = number_following_node_set.first
 			@number_following = node.inner_text()
 			return @number_following
		else
			return @number_following
		end

	end

	def get_num_followers
		if@number_followers == nil then
			number_of_followers_node_set = @content.xpath("(//*[@data-element-term='follower_stats'])[1]")
 			node = number_of_followers_node_set.first
 			@number_followers = node.inner_text()
 			return @number_followers
		else
			return @number_followers
		end
	end

	#fetch the tweets from the first page. This does not assist with infinite scrolling.
	def fetch_base_tweets (min_id=nil)
		container_node_set = @content.xpath("//*[@id='stream-items-id']")
		container_node_set.xpath("./li").each do |t|			
			tweet = Tweet.new
			tweet = parse_tweet_content(tweet,t)
			@tweets << tweet			
		end
		return @tweets
	end

end


module Enumerable
  def in_parallel_n(n)
    todo = Queue.new
    ts = (1..n).map{
      Thread.new{
        while x = todo.deq
          Exception.ignoring_exceptions{ yield(x[0]) } 
        end
      }
    }
    each{|x| todo << [x]}
    n.times{ todo << nil }
    ts.each{|t| t.join}
  end
end