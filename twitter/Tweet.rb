require_relative './String'
require_relative './LogWriter'

#class to help with storage of individual tweet objects
class Tweet
	def initialize(name="",real_name="")
		@tweet_id = 0
		@tweet_content = nil
		@retweet_count = 0
		@favourite_count = 0
		@date_time = nil		
		@raw = nil
		@is_of_page_owner = false
		@name=name
		@real_name = real_name
	end

	#scrape and parse the basic content of a tweet. store this in memory so that we can retrieve it later.
	def scrape_basic_content(t)
			begin
				tweet_id = t.xpath("@data-item-id").text().to_s.strip
				poster_name = t.xpath("//strong/text()").to_s.strip
				#check if the poster is the current user!!
				puts "NAME#{@name}"
				@max_tweet_id = tweet_id
				set_id(tweet_id)
				#puts tweet_id
				tweet_content = t.xpath("./div/div/p/text()").to_s.strip
				#puts tweet_content
				set_content(tweet_content)


			rescue Exception => e
				LogWriter.error(e)
				return self	
			end
	end
	
	#parse the content of a tweet and container node t, saving this to the given
	#tweet object
	def parse_tweet_content (t)
		begin
		tweet_id = t.xpath("@data-item-id").text().to_s.strip
		xpath = '//*[@id="stream-item-tweet-'+tweet_id+'"]/div/div/div[1]/a/strong/text()'
		poster_name = t.xpath(xpath)
		#poster_name = t.xpath('//*[@id="stream-item-tweet-371766472051138560"]/div/div/div[1]/a/strong/text()')
		#check if the poster is the current user!!
		#test_name = poster_name.partition(" ").first
		#puts "is of page owner real name:#{@real_name} poster name: #{poster_name}"
		if @real_name.include?(poster_name.to_s)		
			@is_of_page_owner = true
		end
		@max_tweet_id = tweet_id
		set_id(tweet_id)
		#puts tweet_id
		tweet_content = t.xpath("./div/div/p/text()").to_s.strip
		#puts tweet_content
		set_content(tweet_content)
		#fetching retweets and favourites gets complicated
		if @is_of_page_owner
			fetch_retweet_favourites(t)	
		end
	rescue Exception => e
		LogWriter.error(e)
		return self
	end
	end
	
	# #fetch the retweets and favorites for the tweet
	# def fetch_retweet_favourites(t=nil)
	# 	if t == nil
	# 		t = @raw
	# 	end
	# 	begin
	# 		#to get tweet stats, need to make another async request to twitter
	# 		url = "https://twitter.com/i/expanded/batch/"+get_id+"?facepile_max=7&include%5B%5D=social_proof&include%5B%5D=ancestors&include%5B%5D=descendants"
	# 		LogWriter.debug(url)
	# 		request = RequestHandler.new(url,@user_agent)
	# 		response = request.make_request
	# 		LogWriter.debug("\n\n====================")

	# 		retweets = response.string_between_markers(" Retweeted ", " times")
	# 		if retweets != nil
	# 			LogWriter.debug("retweets:"+retweets)
	# 			set_retweet_count(retweets.strip)
	# 		else
	# 			LogWriter.debug("retweets: UNKNOWN")
	# 			set_retweet_count("0")
	# 		end					
			
	# 		favourites = response.string_between_markers(" Favorited ", " times")

	# 		if favourites != nil
	# 			LogWriter.debug("favourites:"+favourites)
	# 			set_favourite_count(favourites.strip)
	# 		else
	# 			LogWriter.debug("favourites: UNKNOWN")
	# 			set_favourite_count("0")
	# 		end		

	# 		#get the date time values
	# 		fetch_date_time(response)
		
	# rescue Exception => e
	# 	#puts e
	# 	LogWriter.error(e)
	# end
	# end

	def fetch_retweet_favourites(t=nil)
		if t == nil
			t = @raw
		end
		
		begin
			#to get tweet stats, need to make another async request to twitter
			url = "https://twitter.com/Cmdr_Hadfield/status/"+get_id
			#url = "https://twitter.com/i/expanded/batch/"+get_id+"?facepile_max=7&include%5B%5D=social_proof&include%5B%5D=ancestors&include%5B%5D=descendants"
			LogWriter.debug(url)

			request = RequestHandler.new(url)#new user agent for each request
			response = request.make_request			
	
			doc = Nokogiri::HTML(response)
							file = File.open("failboy.html","w")
				file.write(doc)
				file.close
			LogWriter.debug("\n\n====================")
			
			retweets = doc.xpath('//*[@id="page-container"]/div[1]/div[1]/div/div[3]/div[2]/div[4]/ul/li[1]/a/strong/text()').to_s
			#retweets = response.string_between_markers(" Retweeted ", " times")
			if retweets != nil				
				LogWriter.debug("retweets:"+retweets)
				set_retweet_count(retweets.strip)
			else
				LogWriter.debug("retweets: UNKNOWN")
				set_retweet_count("0")
			end					
			
			#favourites = response.string_between_markers(" Favorited ", " times")
			favourites = doc.xpath('//*[@id="page-container"]/div[1]/div[1]/div/div[3]/div[2]/div[4]/ul/li[2]/a/strong/text()').to_s
			if favourites != nil
				LogWriter.debug("favourites:"+favourites)
				set_favourite_count(favourites.strip)
			else
				LogWriter.debug("favourites: UNKNOWN")
				set_favourite_count("0")
			end		

			#get the date time values
			#fetch_date_time(response)
			date_time_val = doc.xpath('//*[@id="page-container"]/div[1]/div[1]/div/div[3]/div[2]/div[5]/span/span/@title').to_s
			if date_time_val != nil and date_time_val.to_s != ""
				set_date_time(date_time_val)					
				LogWriter.debug("date_time:"+date_time_val)	
				return date_time_val
			else			
				LogWriter.debug("date_time: UNKNOWN")
				return "UNKNOWN"
			end		
	rescue Exception => e
		puts "exception parsing tweet #{e}"
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
	rescue Exception => e#do not log the exception, since data time parsing breaks often.
		#LogWriter.error("DATE TIME PARSING EXCEPTION"+e.to_s)#given that this often breaks, it is better to throw this more specific error message
		return "UNKNOWN"
	end
	end
	
	###
	#GETTERS/SETTERS
	###

	#return whether the tweet belongs to the TwitterItems page.
	#i.e. if returns TRUE then the page owner created this tweet.
	#if FALSE, this must be a re-tweet
	#It is assumed that a tweet is re-tweeted, till proven otherwise.
	def is_of_page_owner
		return @is_of_page_owner 
	end

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

	def set_raw_content(raw_content)
		@raw = raw_content
	end

	#getters to help format the month/date/year
	def get_date_month_year
		if @date_time != nil and @date_time.to_s.strip != ""
			date_time_arr = @date_time.to_s.split
			day_month_year = (date_time_arr[date_time_arr.size - 3] + date_time_arr[date_time_arr.size - 2] + date_time_arr[date_time_arr.size-1]).strip
			return day_month_year
		else
			return "UNKNOWN"
		end
	end

	def get_year
		if @date_time != nil and @date_time.to_s.strip != ""
			date_time_arr = @date_time.to_s.split
			year = (date_time_arr[date_time_arr.size - 1]).strip
			return year
		else
			return "UNKNOWN"
		end
	end

	def get_month_year
		if @date_time != nil and @date_time.to_s.strip != ""
			date_time_arr = @date_time.to_s.split
			date_month = (date_time_arr[date_time_arr.size - 2] + date_time_arr[date_time_arr.size-1]).strip
			return date_month
		else
			return "UNKNOWN"
		end
	end

	def set_name name
		@name = name
	end

end
