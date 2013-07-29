require "open-uri"
require "rest-client"
require "crack"
require "hpricot"
require "nokogiri"
require "uri"
require 'openssl'
require "logger"

class LinkedInScraper
		def initialize(url)
		@url = URI.escape(url.to_s)	
		#switch user agents for every single new scraper.
		@userAgent = UserAgent.new
	end

	def scrape
		puts "scraping..." + @url.to_s
		@document = fetch_page
		linkedInItem = LinkedInItem.new(@document,@resp)
		return linkedInItem
	end

	def fetch_page
		@resp = RestClient.get(@url,:user_agent => @userAgent.get_user_agent.to_s)
		@document = Nokogiri::HTML(@resp)
		return @document
	end
end

class LinkedInItem
	def initialize(content,raw)
		@raw = raw
		@content = content		
	end

	def write_to_file(file_name,directory_name)
		begin
			Dir::mkdir(directory_name)
		rescue Exception=>e
		end

		file = File.open(directory_name+"/"+file_name,"w")
		file.write(@raw.to_s)
		file.close
	end
end

class LinkedInSearch

end

class UserAgent

end

class CommandLineInterface
	def initialize
		$logger = Logger.new('logger.log')
		@name_list = LinkedInSearch.new("facebook_urls.txt")
	end

	def set_proxy(proxyname,user,password)
		RestClient.proxy = proxyname
	end
end

cli = CommandLineInterface.new
