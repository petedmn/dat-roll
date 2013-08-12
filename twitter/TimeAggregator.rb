require 'rest-client'
require 'nokogiri'
require 'crack'
require_relative './Tweet'
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




	def cluster_months
		puts "please input a file name"
		file_name = STDIN.gets.chomp
			if file_name == "" or file_name == nil
			arr = @file_name.split("/")
			str = ""
			arr.pop
			arr.each do |s|
				str  << s << "/"
			end	
			file_name = str + "/months.xml"
		end
		file = File.open(file_name,"w")
		overall_impact = compute_impact_factor(@tweets)
		tweet_hash = @tweets.group_by{|t| t.get_month_year}		
		builder = Nokogiri::XML::Builder.new do |xml|
			xml.month_divide{
				xml.overall_impact_ overall_impact
				xml.months{
					tweet_hash.each do |key,tweet|
					date_time = tweet[0].get_month_year
					impact_month = compute_impact_factor(tweet)
						xml.month{
							xml.m_ date_time
							xml.impact_factor_ impact_month
						}	
					end
				}
			}		
		end
		file.write(builder.to_xml)
		file.close		
	end

		def cluster_days
		puts "please input a file name"
		file_name = STDIN.gets.chomp
		if file_name == "" or file_name == nil
			arr = @file_name.split("/")
			str = ""
			arr.pop
			arr.each do |s|
				str  << s << "/"
			end
			file_name = str + "days.xml"
		end
		file = File.open(file_name,"w")
		overall_impact = compute_impact_factor(@tweets)
		tweet_hash = @tweets.group_by{|t| t.get_date_month_year}		
		builder = Nokogiri::XML::Builder.new do |xml|
			xml.day_divide{
				xml.overall_impact_ overall_impact
				xml.days{
					tweet_hash.each do |key,tweet|
					date_time = tweet[0].get_date_month_year
					impact_month = compute_impact_factor(tweet)
						xml.day{
							xml.d_ date_time
							xml.impact_factor_ impact_month
						}	
					end
				}
			}		
		end
		file.write(builder.to_xml)
		file.close		
	end

	def cluster_years
		puts "please input a file name"
		file_name = STDIN.gets.chomp
			if file_name == "" or file_name == nil
			arr = @file_name.split("/")
			str = ""
			arr.pop
			arr.each do |s|
				str  << s << "/"
			end
			file_name = str + "/years.xml"
		end
		file = File.open(file_name,"w")
		overall_impact = compute_impact_factor(@tweets)
		tweet_hash = @tweets.group_by{|t| t.get_year}		
		builder = Nokogiri::XML::Builder.new do |xml|
			xml.year_divide{
				xml.overall_impact_ overall_impact
				xml.years{
					tweet_hash.each do |key,tweet|
					date_time = tweet[0].get_year
					impact_month = compute_impact_factor(tweet)
						xml.year{
							xml.y_ date_time
							xml.impact_factor_ impact_month
						}	
					end
				}
			}		
		end
		file.write(builder.to_xml)
		file.close		
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

class CommandLineInterface

	def initialize			
			if ARGV[0]
				file_name = ARGV[0]
			else
				puts "File Name?"
				file_name = gets.chomp
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
		puts "performing #{action}"
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
		process(select_action)
	end

	def get_file_name
		file_name = gets
	end

	
end

cli = CommandLineInterface.new
