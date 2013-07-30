require 'rest-client'
require './UserAgent'
require './LogWriter'

#Handles searching through the user page on stack overflow
class StackUserList
	
	def initialize
		@base_url = "http://stackoverflow.com/users"
		@user_agent = UserAgent.new
	end
	
	#loop through all users, starting from those on the home page
	def scrape_all
		page = fetch_page(@base_url)
		url_list = get_url_list(page)
		url_list.each do |url|
			#scrape the page
			user = User.new(url)
		end
	end

	def get_url_list(page)
		url_list = Array.new
		#there are 36 users per page(assumption)
		#it is a grid of 4x by 9y
		(1..9).each do |y|
			(1..4).each do |x|
				xpath = "//*[@id='user-browser']/table/tr["+y.to_s+"]/td["+x.to_s+"]/div/div[2]/a/@href"
				puts xpath
				url = page.xpath(xpath)
				url_list << url.to_s
				puts url.to_s
			end			
		end
	end

	#TODO load the next page of users
	def get_next
		
	end

	def fetch_page(url)
		begin
			resp = RestClient.get(url,:user_agent => @user_agent.get_user_agent.to_s)
			page = Nokogiri::HTML(resp)
			LogWriter.info(resp)
			return page
		rescue Exception => e
			LogWriter.error(e)
			throw e#TODO
		end
	end

end
