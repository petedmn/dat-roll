#class to help with storage of individual tweet objects
class Tweet
	def initialize
		@tweet_id = 0
		@tweet_content = nil
		@retweet_count = 0
		@favourite_count = 0
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
