require 'rest-client'
require 'nokogiri'
require 'work_queue'
require 'nokogiri'

class Profile

	def initialize(url,user_agent)
		@url = url
		@user_agent = user_agent
	end

	def scrape
		#first, get the document... No need for infinite scroll on LinkedIn which is nice.
		resp = RestClient.get(@url,:user_agent => @user_agent.get_user_agent.to_s)
		profile_doc = Nokogiri::HTML(resp)
		#now that we have the document, can convert this into meaningful data...
		@num_recommendations = get_recommendations(profile_doc)
		@num_connections = get_num_connections(profile_doc)
		@current_position = get_current_position(profile_doc)
		@skill_list = get_skill_list(profile_doc)
	end

	#the number of people that have recommended this person
	def get_recommendations(doc)
		num_recommendations = doc.xpath('//*[@id="overview"]/dd[2]/p/strong/text()')
		puts "Number of recommendations #{num_recommendations}"
		return num_recommendations
	end

	def get_num_connections(doc)
		num_connections = doc.xpath('//*[@id="overview"]/dd[3]/p/strong/text()')
		puts "number of connections #{num_connections}"
		return num_connections
	end

	def get_current_position(doc)
		current_position = doc.xpath('//*[@id="overview"]/dd[1]/ul/li/text()').to_s.chomp.strip
		puts "current position #{current_position}"
		return current_position
	end

	#get the skills of the person
	def get_skill_list(doc)
		doc.xpath('//*[@id="skills-list"]/li').each do |li|
			skill = li.xpath('./span/text()').to_s.strip
			puts "skill #{skill}"
		end
	end
end