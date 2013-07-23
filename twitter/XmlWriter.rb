require 'nokogiri'
###helper script to assist with writing xml to files

class XmlWriter
	def initialize(item, file_name,directory_name)
		@item = item
		@file_name = file_name
		@directory_name = directory_name
	end
	
	#write the updated item to the file!
	def write_to_file(item=nil,file_name=nil,directory_name=nil)

		if item == nil
			item = @item
		end
		if file_name == nil
			file_name = @file_name
		end	
		if directory_name == nil
			directory_name = @directory_name
		end				
		
		begin
			Dir::mkdir(directory_name)
		rescue Exception=> e
		end
		
		
		puts directory_name+"/"+file_name
		file = File.open(directory_name+"/"+file_name,"w")
		xml = construct_xml(item)
		puts xml
		file.write(xml)		
		file.close
	end	

	def construct_xml(item)
		puts 'building xml'
		tweets = item.@tweets
		number_followers = item.@number_followers
		number_following = item.@number_following
		number_of_tweets = item.@number_of_tweets
		builder = Nokogiri::XML::Builder.new do |xml|
		xml.profile {
			xml.key_values{ 
				xml.number_followers_ number_followers
				xml.number_tweets_ number_of_tweets
				xml.number_following_ number_following
			}
			xml.tweets{
				tweets.each do |t|
					if t.is_a? Tweet
					xml.tweet(:tweet_id => t.get_id){						
        				xml.tweet_content_  t.get_content
        				xml.retweet_count_     t.get_retweet_count
        				xml.favourite_count_ t.get_favourite_count
					xml.date_time_	t.get_date_time

        		}	
        		end
			end
			}				
		}
		end	
		return builder.to_xml
	end
end
