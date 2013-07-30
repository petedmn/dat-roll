require 'rest-client'
require './LogWriter'

class User
	def initialize(url)
		@base_url = "http://stackoverflow.com"
		@url = @base_url + url
	end
	
	#fetch the page
	def fetch
		begin

		rescue Exception => e
			
		end
	end

	#structure the page
	def scrape

	end
end
