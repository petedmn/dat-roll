require 'rest-client'
require 'nokogiri'
require 'crack'
require_relative '../Tweet'
require_relative '../UserAgent'

class TimeAnalysis

	def initialize(file_name)
		@file = File.open(file_name)
	end

	def execute
		xml_string = @file.read
		xml = Nokogiri::XML(xml_string)
		xpath = ("//tweet/@tweet_id")
		xml.xpath(xpath).each do |tweet_id|
			get_date_time(tweet_id)
		end
	end

	def get_date_time(tweet_id)
		url = "https://twitter.com/i/expanded/batch/"+tweet_id+"?facepile_max=7&include%5B%5D=social_proof&include%5B%5D=ancestors&include%5B%5D=descendants"
		response = get_url(url)
		tweet = Tweet.new
		puts tweet.fetch_date_time(response)
	end

	def get_url(url)
		user_agent = UserAgent.new
		response = RestClient.get(url,:user_agent => user_agent.get_user_agent.to_s)
	end

end

if ARGV[0]
	file_name = ARGV[0]
	RestClient.proxy = ENV['http_proxy']
	time = TimeAnalysis.new(file_name)
	time.execute
else
 exit "please input a file to analyse time values for!"
end
