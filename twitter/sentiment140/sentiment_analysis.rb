require_relative '../Tweet'
require 'rest-client'
require 'crack'
require 'nokogiri'
require 'json'
require 'csv'

class Sentiment
	#load whole shitload of tweets
	def initialize(directory_name)
		@dir_name = directory_name
	end

	def loop_files
		Dir.foreach(@dir_name) do |file_name|
			next if file_name == '.' or file_name == '..' or !(file_name.include?('.xml'))
				load_tweets file_name
		end
	end

	#load the tweets for a given file, corresponding to data from a twitter account
	def load_tweets file_name
		doc =Nokogiri::XML(File.open(@dir_name+"/"+file_name).read)
		xpath = "//tweet"
		content = Array.new
		doc.xpath(xpath).each do |tweet|
			t = Tweet.new
			text = tweet.xpath("./tweet_content/text()").to_s
			t.set_content(text)
			retweets = tweet.xpath("./retweet_count/text()").to_s
			t.set_retweet_count(retweets)
			content <<  t
		end
		fetch_sentiment(content,file_name)
	end

	#fetch tweet sentiment data from Sentiment140 interface.
	#see if impact correlates positively with sentiment data. 
	def fetch_sentiment tweet_content,file_name
		jsonArray = Array.new
		tweet_content.each do |tweet|
			jsonArray << {"text" => tweet.get_content, "retweets" => tweet.get_retweet_count}
		end
		#build the JSON request object.
		json = {
			:data => jsonArray
		}
		url= "http://www.sentiment140.com/api/bulkClassifyJson?appid=immachumm@gmail.com"
		RestClient.proxy = ENV['http_proxy']
		response = RestClient.post(url, json.to_json, :content_type => 'application/json', :timeout => '5')
		#puts response
		response_json = JSON.load(response)
		#response_json = Crack::JSON.parse(response)
		write_sentiment_csv(response_json, file_name)
	end

	#write sentiment 0 = negative, 2 = neutral, 4 = positive
	#json is a hash at this point, which we can pull data from
	#and write to file.
	def write_sentiment_csv(json,file_name)
		file_name = file_name.gsub(".xml","")	
		file = File.open(@dir_name+"/#{file_name}.csv","w")#open file with xml removed, csv format FTW
		array = json["data"]
		csv_string = CSV.generate do |csv|
			csv << ["text","retweet_count","polarity","pol_val"]
			array.each do |inner|
				text = inner["text"]
				retweets = inner["retweets"]
				polarity = inner["polarity"].to_s.chomp
				pol_val = 'neut'
				puts "POLARITY #{polarity};"
				if polarity.to_s == '0'
					puts "NEG"
					pol_val = 'neg'
				elsif polarity.to_s == '2'
					puts "NEUT"
					pol_val = 'neut'
				elsif polarity.to_s == '4'
					puts "POS"
					pol_val = 'pos'
				end					
				csv << [text,retweets,polarity,pol_val]
			end
		end
		#write this to the csv...
		file.write(csv_string)
	end
end

class CommandLineInterface
	def initialize
		await_input
	end

	def await_input(msg = "")
		puts msg
		puts "please input a directory name..."
		dir_name = STDIN.gets.chomp
		sent = Sentiment.new(dir_name)
		begin
			sent.loop_files
		rescue Exception => e
			puts "EXCEPTION RECEIVED#{e}"
			await_input("INVALID DIR NAME")
		end
	end
end

cli = CommandLineInterface.new