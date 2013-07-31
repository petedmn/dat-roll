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
		tweet_loader = TweetLoader.new(file_name)
		@tweets = tweet_loader.get_tweets
	end

	def set_proxy
		RestClient.proxy = ENV['http_proxy']
	end
	
		#load data from current month, then go back in time month by month.
		#for each month, compute the 'impact factor' for that month.
		#then graph that shit
	def cluster_months
		@tweets.each do |tweet|
			puts tweet.get_retweet_count
			puts tweet.get_date_time
		end
	end

	def cluster_days

	end

	def cluster_years

	end

	def output

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
		puts "Options; days\n months\n years\n time"
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
