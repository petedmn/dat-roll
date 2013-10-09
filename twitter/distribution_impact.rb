require 'rest-client'
require 'nokogiri'
require 'crack'
require 'csv'
require_relative './Tweet'
require_relative './Time_Analysis'
require_relative './XmlLoader'

class Distribution_Impact

	def initialize(directory_name)
		compute_impact_factor_for_dir(directory_name)
	end

	#get dat tweet loader to do its thing - by default from the file name field
	def load_xml(file_name = @file_name)
		puts "loading xml..."+file_name
		tweet_loader = TweetLoader.new(file_name)
		tweet_loader.load_tweets
		tweets = tweet_loader.get_tweets
		return tweets
	end


	def compute_impact_factor_for_dir(directory_name)
		hash = Hash.new
		Dir.foreach(directory_name) do |file_name|
			next if file_name == '.' or file_name == '..'
		  tweets=	load_xml(directory_name+"/"+file_name)
			overall_impact = compute_impact_factor(tweets)
			hash[file_name] = overall_impact
		end
		 csv_string = CSV.generate do |csv|
		 	csv << ["file_name","impact"]
		 	hash.each do |key,value|
		 		csv << [key,value]
		 	end
		 end
		 file = File.open("clustered_impact3.csv","w")
		 file.write(csv_string)
		 file.close
	end
	
	#compute impact factor for the current month
	def compute_impact_factor(tweets)
		retweets = Array.new
		tweets.each do |tweet|
			retweets << tweet.get_retweet_count
		end
		retweets = retweets.sort
		retweets = retweets.reverse
		h_index = get_h_index(retweets)
		puts "H_INDEX"+ h_index.to_s
		return h_index
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

di = Distribution_Impact.new("/vol/projects/kris/OpenRep/Iain/final_dataset")
