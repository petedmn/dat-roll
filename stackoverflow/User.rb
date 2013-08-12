require 'rest-client'
require 'nokogiri'
require './LogWriter'

class User
	def initialize(url,user_agent)
		@user_agent = user_agent
		@base_url = "http://stackoverflow.com"
		@url = @base_url + url
	end

	#do all the available actions with regards to fetching the user
	def get_all_info
		page = fetch
		scrape(page)
	end
	
	#fetch the page and return a structured version of it.
	def fetch
		begin
			response = RestClient.get(@url,:user_agent => @user_agent.get_user_agent)
			doc = Nokogiri::HTML(response)
			return doc
		rescue Exception => e
			LogWriter.error(e)
			throw e
		end
	end

	#structure the page
	def scrape(page)
		
	end
end
