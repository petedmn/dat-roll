require_relative './String'
require_relative './LogWriter'

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
		LogWriter.error(e)
		return self
	end
	end
	
	#fetch the retweets and favorites for the tweet
	def fetch_retweet_favourites(t)
		begin
			#to get tweet stats, need to make another async request to twitter
			url = "https://twitter.com/i/expanded/batch/"+get_id+"?facepile_max=7&include%5B%5D=social_proof&include%5B%5D=ancestors&include%5B%5D=descendants"
			LogWriter.debug(url)
			request = RequestHandler.new(url,@user_agent)
			response = request.make_request
			LogWriter.debug("\n\n====================")

			retweets = response.string_between_markers(" Retweeted ", " times")
			if retweets != nil
				LogWriter.debug("retweets:"+retweets)
				set_retweet_count(retweets.strip)
			else
				LogWriter.debug("retweets: UNKNOWN")
				set_retweet_count("0")
			end					
			
			favourites = response.string_between_markers(" Favorited ", " times")

			if favourites != nil
				LogWriter.debug("favourites:"+favourites)
				set_favourite_count(favourites.strip)
			else
				LogWriter.debug("favourites: UNKNOWN")
				set_favourite_count("0")
			end		

			#get the date time values
			fetch_date_time(response)
		
	rescue Exception => e
		#puts e
		LogWriter.error(e)
	end
	end

	#fetch the date and time values for the tweet
	#TODO - this often breaks due inconsistent response format!!
	def fetch_date_time(response)
	begin			
		date_time_val = response.string_between_markers("tweet-timestamp","\\u003E").strip
		date_time_val = date_time_val.string_between_markers("js-permalink js-nav\\\" title=\\\"","\\\"")
		if date_time_val != nil and date_time_val.to_s != ""
			set_date_time(date_time_val)		
			LogWriter.debug("date_time:"+date_time_val)	
			return date_time_val
		else			
			LogWriter.debug("date_time: UNKNOWN")
			return "UNKNOWN"
		end
	rescue Exception => e
		LogWriter.error("DATE TIME PARSING EXCEPTION"+e.to_s)#given that this often breaks, it is better to throw this more specific error message
		return "UNKNOWN"
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
