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
	end



end