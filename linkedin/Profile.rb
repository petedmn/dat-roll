require 'rest-client'
require 'nokogiri'
require 'work_queue'
require 'nokogiri'

class Profile

	def initialize(url,user_agent,id)
		@url = url
		@user_agent = user_agent
		@id = id
	end

	def scrape
		#first, get the document... No need for infinite scroll on LinkedIn which is nice.
		resp = RestClient.get(@url,:user_agent => @user_agent.get_user_agent.to_s)
		profile_doc = Nokogiri::HTML(resp)
		#now that we have the document, can convert this into meaningful data...
		@num_recommendations = find_recommendations(profile_doc)
		@num_connections = find_num_connections(profile_doc)
		@current_position = find_current_position(profile_doc)
		@skill_list = find_skill_list(profile_doc)
		@groups_associations = find_groups_associations(profile_doc)
	end

	def find_name(doc)

	end

	#the number of people that have recommended this person
	def find_recommendations(doc)
		num_recommendations = doc.xpath('//*[@id="overview"]/dd[2]/p/strong/text()')
		#puts "Number of recommendations #{num_recommendations}"
		return num_recommendations.to_s.gsub(/\s+/, ' ')
	end

	def find_num_connections(doc)
		num_connections = doc.xpath('//*[@id="overview"]/dd[3]/p/strong/text()')
		#puts "number of connections #{num_connections}"
		return num_connections.to_s.gsub(/\s+/, ' ')
	end

	def find_current_position(doc)
		current_position = doc.xpath('//*[@id="overview"]/dd[1]/ul/li/text()').to_s.chomp.strip
		#puts "current position #{current_position}"
		return current_position.to_s.gsub(/\s+/, ' ')
	end

	#get the skills of the person
	def find_skill_list(doc)
		skill_list = Array.new
		doc.xpath('//*[@id="skills-list"]/li').each do |li|
			skill = li.xpath('./span/text()').to_s.strip
			fixed_skill = skill.gsub(/\s+/, ' ')
			#puts "skill #{skill}"
			skill_list << fixed_skill
		end
		return skill_list
	end

	def find_groups_associations(doc)
		groups = Array.new
		doc.xpath('//*[@id="pubgroups"]/ul/li').each do |li|
			org = li.xpath('./div/a/strong/text()').to_s.strip
			groups << org.gsub(/\s+/, ' ')
		end
		return groups
	end

	############################
	#GETTERS/SETTERS
	############################
	def get_num_recommendations
		return @num_recommendations
	end

	def get_num_connections
		return @num_connections
	end

	def get_current_position
		return @current_position
	end

	def get_skills
		return @skill_list
	end

	def get_groups
		return @groups_associations
	end

	def get_id
		return @id
	end
end