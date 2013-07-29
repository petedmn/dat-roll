require 'nokogiri'
require './LogWriter'

##script to calculate an influence value, given a xml input

#h-index formula works from the first paper to the end....

#retweet - number

#calculate influence based on twitter stuff!

#Total number of tweets - measures productivity, activity. Does not measure importance/influence of individual tweets

#Total number of retweets - measures total impact. Disadvantage: can be inflated by outliers. e.g. some twitter pages have a very
#small number of retweets/favourites for a long time, and then all of a sudden one massive one.

#retweets per tweet; allow comparison of individuals of different age, 
#rewards low productivity, penalises high productivity

#Number of significant tweets; defined as the number of tweets with >y retweets. E.g. y = 40. Advantae, eliminates disadvantages of above criteria,
#gives an idea of broad and sustained impact. Disadvantage is that y is arbitrary and will randomly favour or disfavour people, and needs
#to be adjusted for different levels of seniority - e.g. number of followers!

#Nunber of citations to each of the q most-cited papers, e.g. q=5. Adv: overcomes many of the disadvantages of criteria defined above
#Disadvantage: y is arbitrary, will randomly favour or disfavour individuals. 

#PROPOSED H - INDEX

class TwitterInfluence
	def initialize(dir_name)
		@dir_name = dir_name		
	end

	def main
		Dir.foreach(@dir_name) do |item|
			next if item == '.' or item == '..'
			@name = item
			#do work on real items
			calculate(item)				
		end
	end

	def calculate(file_name)
		xml = parse_file(file_name)		
		#number of followers		
		retweets = parse_tweets(xml)
		puts "number of tweets:"+retweets.size.to_s
		h_index = get_h_index(retweets)
		num_followers = get_num_followers(xml).to_s
		num_tweets = get_num_tweets(xml).to_s
		puts "H INDEX;"+h_index.to_s
		puts "BUT NUMBER OF FOLLOWERS;"+num_followers
		#the h-index is the point at which the number of papers = the number of citations... 		
		save_results(h_index.to_s,num_followers.to_s,@name.to_s,num_tweets,retweets.size.to_s)
	end

	def save_results(h_index, num_followers, name,num_tweets=nil,num_recorded_tweets=nil)
		LogWriter.data("Name;"+name)
		LogWriter.data("H-INDEX;"+h_index)	
		LogWriter.data("Number of followers;"+num_followers)
		if num_tweets != nil
			LogWriter.data("Num tweets;"+num_tweets)
			LogWriter.data("Number of recorded tweets;"+num_recorded_tweets)
		end	
	end

	#go through the retweet array, to the point at which the number of papers = the number of retweets
	#PRE: the retweet array must be ordered descending, and have no nil values
	def get_h_index(retweets)
		i=0
		retweets.each do |tweet|			
			if i == tweet or i > tweet
				return i
			end
			i = i + 1	
		end
	end

	#returns a descending list of retweet count for the tweets
	def parse_tweets(xml)
		retweets = Array.new
		xml.xpath("//tweet").each do |tweet|			
			count = get_retweets(tweet)
			retweets << count
			#puts count
		end
		retweets = retweets.sort
		retweets = retweets.reverse
		return retweets	
	end

	def get_retweets(tweet)
		tweet.xpath("./retweet_count").each do |node|
			retweets = node.text().strip.to_i
			if retweets.is_a? Integer
				return retweets
			else 
				return 0
			end
		end
	end

	def get_num_followers(xml)
		xml.xpath("//number_followers").each do |node|
			followers = node.text().chomp("Followers").strip
			return followers.chomp("Followers").strip
		end
	end

	def get_num_tweets(xml)
	xml.xpath("//number_tweets").each do |node|
			num_tweets = node.text().chomp("Tweets").strip
			return num_tweets.chomp("Tweets").strip
		end
	end

	def parse_file(file_name)	
		file = File.open(@dir_name+file_name)
		file_content = file.read
		return Nokogiri::XML.parse(file_content)		
	end

end

#usage - loop through a directory of results, calculating influence data for each xml file in this directory

if ARGV[0]
	dirname = ARGV[0]
	influence = TwitterInfluence.new(dirname)
	influence.main
else
	return "Need argument - directory name"
end


