require "rest-client"
require "nokogiri"
require "uri"
require "logger"
require './UserAgent'

#provides functionality to search for profiles, based on first/last names,
#using the linked in search mechanism
class LinkedInSearch

	def initialize(name_file,results_directory)
		RestClient.proxy = ENV['http_proxy']
		@name_file = name_file
		@results_dir = results_directory	
		@user_agent = UserAgent.new
	end

	def search_through_names
		nf = File.open(name_file)
		nf.each_line do |line|
			if line != nil
				url_to_search = construct_search_url(line.chomp)
				url_list_to_scrape = get_profile_url_list#could parrelize at this level.
				url_list_to_scrape.each do |profile_url|
					scrape_profile(profile_url)
				end	
			end
		end
	end

	#call the profile-level scraper code to actually scrape and store this profile.
	def scrape_profile(profile_url)
		profile = Profile.new(profile_url,@user_agent)
		profile.scrape
	end

	#simple helper method to construct the search URL
	def construct_search_url(first,last=nil)		
		#construct the search URL
		base_url = "http://www.linkedin.com/pub/dir/?"
		if first != nil
			base_url << "first=#{first}"
		end
		if last != nil 
			base_url << "&last=#{last}"
		else
			base_url << "&last=Search"
		end
		base_url << "&search=Search&searchType=fps"
		puts "url... #{base_url}"
		return base_url
	end

	#loads the list of names, returns a list of URLs that
	#can be used to view profiles.
	def get_profile_url_list
		#first, load the page..
		resp = RestClient.get(@base_url,:user_agent => @user_agent.get_user_agent.to_s)
		doc = Nokogiri::HTML(@resp)
		xpath = '//*[@id="result-set"]/ol'
		doc.xpath(xpath).each do |li|
			puts li
		end
	end

end

class CommandLineInterface
	def initialize(name_file,results_dir)
		$logger = Logger.new('logger.log')
		@name_list = LinkedInSearch.new(name_file,results_dir)
	end	
end

if ARGV[0] == nil
	puts "USAGE - ruby LinkedIn.rb [Filename]"
	exit 1
end
name_file = ARGV[0]
results_dir = '/vol/projects/kris/OpenRep/Iain/linkedin/results'

cli = CommandLineInterface.new(name_file,results_dir)
