require "rest-client"
require "nokogiri"
require "uri"
require "logger"
require 'csv'
require 'work_queue'
require './UserAgent'
require './Profile'

#provides functionality to search for profiles, based on first/last names,
#using the linked in search mechanism
class LinkedInSearch

	def initialize(name_file,results_directory)
		RestClient.proxy = ENV['http_proxy']
		@name_file = name_file
		@results_dir = results_directory	
		@user_agent = UserAgent.new
	end

	#loop through the given names file, and scrape the results that we find on twitter
	def search_through_names
		profile_list = Array.new
		i=0.0
		nf = File.open(@name_file)
		nf.each_line do |line|
			if line != nil
				i = i + 1.0
				url_to_search = construct_search_url(line.chomp)
				if url_to_search != false
				url_list_to_scrape = get_profile_url_list(url_to_search)
				if url_list_to_scrape != nil #just check that there are profiles to scrape in this list...
					url_list_to_scrape.each do |profile_url|#could parrelize at this level.
						i=i+0.1
						profile_list << scrape_profile(profile_url.to_s,i)
					end	
				end
			end
			end
		end
		save_profiles_to_xml(profile_list)
	end	

	#call the profile-level scraper code to actually scrape and store this profile.
	def scrape_profile(profile_url,id)
		profile = Profile.new(profile_url,@user_agent,id)
		profile.scrape
		return profile
	end

	#simple helper method to construct the search URL
	def construct_search_url(first,last=nil)		
		#construct the search URL
		base_url = "http://www.linkedin.com/pub/dir/?"
		if first != nil
			base_url << "first=#{first}"
		else
			return false#require a first name.
		end
		if last != nil 
			base_url<<"&last=#{last}"
		else
			base_url<< "&last="
		end
		base_url<< "&search=Search&searchType=fps"
		puts "url... #{base_url}"
		return base_url.to_s
	end

	#loads the list of names, returns a list of URLs that
	#can be used to view profiles.
	def get_profile_url_list(url)
		begin
		url_list = Array.new
		#first, load the page..
		resp = RestClient.get(url,:user_agent => @user_agent.get_user_agent.to_s)
		doc = Nokogiri::HTML(resp)
		xpath = '//*[@id="result-set"]/li'
		doc.xpath(xpath).each do |li|
			href = li.xpath('./h2/strong/a/@href')
			url_list << href
		end
		return url_list
		rescue Exception => e#it is possible that we will get 404 Not Found Exceptions at this point,
			#given any names that do not exist on LinkedIn. Unlikely but possible.
			puts "Exception #{e}"
		end
	end

	#save the given profiles to a single file
	#xml format.
	def save_profiles_to_xml(profile_list)
		puts 'saving results to xml document'
		builder = Nokogiri::XML::Builder.new do |xml|
			xml.profiles{
				profile_list.each do |p|			
				xml.profile(:id=>p.get_id.to_s){		
					xml.num_connections_ p.get_num_connections
					xml.num_recommendations_ p.get_num_recommendations
					xml.current_position_ p.get_current_position
					xml.skills(:num_skills => p.get_skills.length){
						p.get_skills.each do |skill|
							xml.skill_ skill
						end
					}
					xml.groups(:num_groups => p.get_groups.length){
						p.get_groups.each do |group|
							xml.group_ group
						end
					}
					}						
				end

			}
		end
		time = Time.now
		t_f = time.mon.to_s+time.day.to_s+time.hour.to_s+time.min.to_s
		#Dir.mkdir("#{@results_dir}/run#{time}")
		file = File.open("#{@results_dir}/run#{t_f}.xml","w")
		file.write(builder.to_xml.to_s)
	end

	#save the given profiles to a single file.
	#csv format.
	def save_profiles_to_csv(profile_list)
		#TODO
	end


end

class CommandLineInterface
	def initialize(name_file,results_dir)
		$logger = Logger.new('logger.log')
		@search = LinkedInSearch.new(name_file,results_dir)
	end	

	def execute
		@search.search_through_names
	end
end

if ARGV[0] == nil
	puts "USAGE - ruby LinkedIn.rb [Filename]"
	exit 1
end
name_file = ARGV[0]
results_dir = '/vol/projects/kris/OpenRep/Iain/linkedin/results'

cli = CommandLineInterface.new(name_file,results_dir)
cli.execute
