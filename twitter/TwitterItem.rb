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


#a Twitter Item takes a twitter page as an xml document
#and turns it into structured, useful data.
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
	end

	#method to automatically evaluate the various fields e.g. num tweets, following,followers
	def parse
		get_num_tweets
		get_num_following
		get_num_followers
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

	#fetch tweets, starting from the minimum ID. if no min ID given
	#will fetch all available tweets.
	def fetch_tweets (min_id=nil)
		container_node_set = @content.xpath("//*[@id='stream-items-id']")
		container_node_set.xpath("./li").each do |t|			
			tweet = Tweet.new
			tweet = parse_tweet_content(tweet,t)
			@tweets << tweet			
		end
		return @tweets
	end

	#parse the content of a tweet and container node t, saving this to the given
	#tweet object
	def parse_tweet_content (tweet, t)
		start_time = Time.now
		LogWriter.debug("Parsing tweet.. START")
		begin
		tweet_id = t.xpath("@data-item-id").text().to_s.strip
		@max_tweet_id = tweet_id
		tweet.set_id(tweet_id)
		#puts tweet_id
		tweet_content = t.xpath("./div/div/p/text()").to_s.strip
		#puts tweet_content
		tweet.set_content(tweet_content)

		#fetching retweets and favourites gets complicated
		tweet = fetch_retweet_favourites(tweet,t)	

	rescue Exception => e
		logger.info(e)
	end
		end_time = Time.now
		time_taken = (end_time - start_time).to_s
		LogWriter.debug("Parsing tweet.. END SUCCESFUL")
		LogWriter.parse_performance("Time taken to parse tweet;"+time_taken)
		return tweet
	end	

	def fetch_retweet_favourites(tweet, t)
		begin
			tweet.fetch_retweet_favourites(t)
			return tweet
			###BELOW CODE IS NO LONGER USED
			puts "FETCHING RETWEETS, WRONG PLACE"
			#sleep(4)#as I do not want to get blocked
			var = "//*[@id='stream-item-tweet="+tweet.get_id+"']/ol/li[1]/div/div/div[3]/div/div[4]/ul/li[1]/a/strong/text()"
			retweet_count = t.xpath(var)
			#puts retweet_count
			#to get tweet stats, need to make another async request to twitter
			url = "https://twitter.com/i/expanded/batch/"+tweet.get_id+"?facepile_max=7&include%5B%5D=social_proof&include%5B%5D=ancestors&include%5B%5D=descendants"
			request = RequestHandler.new(url,@user_agent)
			response = request.make_request

			#find retweets
			retweets = response.string_between_markers(" Retweeted ", " times")
			tweet.set_retweet_count(retweets.strip)
			#puts "retweeted:"+retweets
			#find favourites
			favourites = response.string_between_markers(" Favorited ", " times")
			#puts "favourited:" + favourites
			tweet.set_favourite_count(favourites.strip)

				#date_time
			date_time_val = response.string_between_markers("tweet-timestamp","\\u003E").strip
			puts "DATE TIME VAL;"+date_time_val
			date_time_val = date_time_val.chomp("\\")
			tweet.set_date_time(date_time_val)
							

			file = File.open("lol.html","w")
			file.write(response)
			file.close
			###END CODE NO LONGER USED
	rescue Exception => e
	
		puts e
		throw e
	end
	end

	#tweet parser for the JSON response for infinite scrolling.
	#add these tweets to the tweet array for the page we are parsing
	def	fetch_extra_tweets(json)
		LogWriter.test("parsing extra tweets.. START")
		#we have a hash of values to deal with....
		#puts "parsing the extra tweets"	
		#puts json["max_id"]
		@max_tweet_id = json["max_id"]
		#puts "new max id"+@max_tweet_id
		@has_more = json["has_more_items"]
		content_to_parse = json["items_html"]

 		container_node_set = Nokogiri::HTML(content_to_parse)	

 		container_node_set.xpath("html/body/li").each do |t|
 			tweet = Tweet.new
 			tweet.parse_tweet_content(t)
 			@tweets << tweet
 		end		
	  LogWriter.test("parsing extra tweets.. END")
		return @has_more
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
		LogWriter.debug("START write to file...")
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
		LogWriter.debug("Write to file finished SUCCESFUL")
		LogWriter.storage_performance("Time taken;"+time_taken)
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

end
