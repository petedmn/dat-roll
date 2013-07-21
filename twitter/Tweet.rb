#class to help with storage of individual tweet objects
class Tweet
	def initialize()
		@tweet_id = 0
		@tweet_content = nil
		@retweet_count = 0
		@favourite_count = 0
		@date_time = nil
	end


	
	#parse the content of a tweet and container node t, saving this to the given
	#tweet object
	def parse_tweet_content (t)
		begin
		tweet_id = t.xpath("@data-item-id").text().to_s.strip
		@max_tweet_id = tweet_id
		set_id(tweet_id)
		#puts tweet_id
		tweet_content = t.xpath("./div/div/p/text()").to_s.strip
		#puts tweet_content
		set_content(tweet_content)

		#fetching retweets and favourites gets complicated
		fetch_retweet_favourites(t)	

		
	rescue Exception => e
		#logger.info(e)
		return this
	end
	end
	
	#fetch the retweets and favorites for the tweet
	def fetch_retweet_favourites(t)
		begin
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
			set_retweet_count(retweets.strip)
			#puts "retweeted:"+retweets
			#find favourites
			favourites = response.string_between_markers(" Favorited ", " times")
			#puts "favourited:" + favourites
			set_favourite_count(favourites.strip)

			file = File.open("lol.html","w")
			file.write(response)
			file.close
	rescue Exception => e
		#$logger.info(e)
	end
	end

	###
	#GETTERS/SETTERS
	###

	def set_date_time date_time
		@date_time = date_time
	end

	def get_date_time
		return @date_time
	end

	def set_id tweet_id
		@tweet_id = tweet_id
	end

	def get_id
		return @tweet_id
	end

	def set_content tweet_content
		@tweet_content = tweet_content
	end

	def get_content
		return @tweet_content
	end

	def set_retweet_count retweet_count
		@retweet_count = retweet_count
	end

	def get_retweet_count
		return @retweet_count
	end

	def set_favourite_count favourite_count
		@favourite_count = favourite_count
	end

	def get_favourite_count
		return @favourite_count
	end

end
