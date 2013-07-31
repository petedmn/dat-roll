require 'rest-client'
require 'nokogiri'
require 'crack'
require_relative './Time_Analysis'
require_relative './XmlLoader'

#Analysis tool class to assist with temporal data. Look at grouping data into time periods.
class TimeAggregator
	def initialize(file_name)
		@file_name = file_name
		#load in the xml file to start with
		load_xml
	end

	#get dat tweet loader to do its thing - by default from the file name field
	def load_xml(file_name = @file_name)
		puts "loading xml..."+file_name
		tweet_loader = TweetLoader.new(file_name)
		tweet_loader.load_tweets
		@tweets = tweet_loader.get_tweets
	end

	def set_proxy
		RestClient.proxy = ENV['http_proxy']
	end
	
		#load data from current month, then go back in time month by month.
		#for each month, compute the 'impact factor' for that month.
		#then compute that shit in a nice format that can be graphed, foo!
		#this currently has O(n^2) complexity, would be nicer to reduce this.
	def cluster_months
		impact_factor_hash = Hash.new
		overall_impact = compute_impact_factor(@tweets)
		tweets = @tweets
		tweets.each do |tweet|
		tweet_date_time = tweet.get_date_time.to_s
			if tweet_date_time != 'UNKNOWN' and tweet_date_time != nil and tweet_date_time!= ""			
				puts tweet_date_time
				arr = tweet_date_time.split
				puts arr
				month = arr[arr.size-2] + arr[arr.size-1]
				#the tweets list naturally goes back in time.
				current_month_tweets = Array.new
				tweets.each do |inner|					
					if inner != tweet
						inner_dt = inner.get_date_time.to_s
						inner_arr = inner_dt.split
						if inner_arr[inner_arr.size - 2] != nil and inner_arr[inner_arr.size-1] != nil
							inner_month = inner_arr[inner_arr.size - 2] + inner_arr[inner_arr.size-1]
							if inner_month.strip == month.strip
								#we have the same month								
								current_month_tweets << inner
							end
						end
					end
				end	
				tweets.delete(tweet)
				#ok have gathered all the tweets for the current month
				#puts "MONTH"+month.to_s + " IMPACT "+compute_impact_factor(current_month_tweets).to_s
				impact_factor_hash[month] = compute_impact_factor(current_month_tweets)
			end
		end
		#now do some stuff with impact factor array
		save_month impact_factor_hash overall_impact #save the array
	end

	#save our results!
	def save_month(impact_factor_hash,overall_impact)
		puts "Please input a file name which can be saved to"
		file_name = STDIN.gets

		file = File.open(file_name,"w")
		builder = Nokogiri::XML::Builder.new do |xml|
			xml.month_divide{
			xml.overall_impact_ overall_impact
			xml.months{
			impact_factor_hash.each do |month,impact_factor|				
					xml.month_ month
					xml.impact_ impact_factor				
			end
		}
	}
		end
		file.write(builder.to_xml)
		file.close		
	end

	def cluster_days
		puts "STUB"
	end

	def cluster_years
		puts "STUB"
	end

	def output
		puts "STUB"
	end
	
	#compute impact factor for the current month
	def compute_impact_factor(tweets)
		retweets = Array.new
		tweets.each do |tweet|
			retweets << tweet.get_retweet_count
		end
		retweets = retweets.sort
		retweets = retweets.reverse
		return get_h_index(retweets)
	end

	def get_h_index(retweets)
		i=0
		retweets.each do |tweet|			
			count = tweet.strip.to_i
			if i == count or i > count
				return i
			end
			i = i + 1	
		end
	end

end

class CommandLineInterface

	def initialize			
			if ARGV[0]
				file_name = ARGV[0]
			else
				puts "File Name?"
				file_name = gets
			end
			@analysis = TimeAnalysis.new(file_name)
			@time_aggregator = TimeAggregator.new(file_name)
			action = select_action		
			process(action)
	end

	def select_action
		puts "Action?"
		puts "Options; days\n months\n years\n time\n"
		action = STDIN.gets.chomp
		if action == 'days' or action == 'months' or action == 'years'or action == 'exit' or action == 'time'
			return action
		else
			puts "invalid action;"+action
			puts "please try again"
			select_action
		end
	end

	def process action
		if action == 'days'
			@time_aggregator.cluster_days	
		elsif action == 'months'
			@time_aggregator.cluster_months
		elsif action == 'years'
			@time_aggregator.cluster_years
		elsif action == 'time'
			@analysis.execute
			@analysis.save
		elsif action == 'exit'
			puts "good-bye"
			exit 1
		end
		puts "done"
		select_action
	end

	def get_file_name
		file_name = gets
	end

	
end

cli = CommandLineInterface.new
