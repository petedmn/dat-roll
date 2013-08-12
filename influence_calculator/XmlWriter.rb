require 'nokogiri'

class XMLWriter

	def self.write(file_name)


puts 'building xml'		
		builder = Nokogiri::XML::Builder.new do |xml|
		xml.profile {
			xml.key_values{ 
				xml.number_followers_ @number_followers
				xml.number_tweets_ @number_of_tweets
				xml.number_following_ @number_following
			}
			xml.tweets{
				@tweets.each do |t|
					if t.is_a? Tweet
					xml.tweet(:tweet_id => t.get_id){						
        				xml.tweet_content_  t.get_content
        				xml.retweet_count_     t.get_retweet_count
        				xml.favourite_count_ t.get_favourite_count

        		}	
        		end
			end
			}				
		}
		end	
		return builder.to_xml
end
