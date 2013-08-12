require 'nokogiri'
require 'csv'
require_relative './XmlLoader'

#this takes a 
class XMLToCSV

	def initialize file_name
		@xml_loader = TweetLoader.new(file_name)
		@xml_loader.load_tweets
		@tweets = @xml_loader.get_tweets
		@file = File.open(file_name)
	end

	#do the conversion, and output as a csv string.
	def convert
		xmldoc = Nokogiri::XML(@file)		
		#core data
		csv_string = CSV.generate do |csv|
			csv << ["name","number_followers","number_following","number_tweets"]
			num_followers = xmldoc.xpath("//number_followers/text()").to_s.chomp()
			num_following = xmldoc.xpath("//number_following/text()").to_s.chomp()
			num_tweets = xmldoc.xpath("//number_tweets/text()").to_s.chomp()
			csv << ["test",num_followers,num_following,num_tweets]

			#now generate data for each of the tweets.
			csv << ["tweet_id","retweet_count","favourite_count","date_time"]
			@tweets.each do |tweet|
				id = tweet.get_id
				puts "ID #{{id}}"
				retweet_count = tweet.get_retweet_count
				favourite_count = tweet.get_favourite_count
				date_time = tweet.get_date_time
				csv << [id.to_s,retweet_count.to_s,favourite_count.to_s,date_time.to_s]
			end
		end
		return csv_string
	end

end

class CommandLineInterface

	def initialize(input_directory, output_file_name)
		output_file = File.open(output_file_name,"w")
		Dir.foreach(input_directory) do |file_name|
			next if file_name == '.' or file_name == '..'
			if file_name.include?(".xml")
				#convert the file into csv...
				to_csv = XMLToCSV.new(input_directory+"/"+file_name)
				csv_str = to_csv.convert
				output_file.write(csv_str)
			end
		end
	end

end

if !ARGV[0] or !ARGV[1]
	puts "Error - no directory name present. Usage [directory_name, output_file_name]"
	exit 1
end

input_directory = ARGV[0]
output_file = ARGV[1]


cli = CommandLineInterface.new(input_directory,output_file)