require 'nokogiri'
require 'mechanize'
require 'rest-client'
require_relative './UserAgent'

class Crawler

	#we start with a given profile. 
	#profile_name = the profile to start with
	#agent is the current mechanize object; we are able to use this to remain authenticated through the current page.
	def initialize(profile_name,agent)
		@profile_name = profile_name
		@agent = agent
	end	 

	#we need to loop through profiles, and gather follower/following details for these profiles
	#this is kind of the main method for our crawler.

	#then, we can go through tweets and look at who is retweeting these. 
	def execute(num_profiles=0) #might start using number of profiles as an argument later;not needed at this point.
		#first, load the base profile.
		page = search_page(@agent,@profile_name)
		
		#now click the first link on the page, in order to access this page.

	end

	#search for a page with the given profile name
	def search_page(agent,profile_name)
		current_page = agent.page

		searched_page = current_page.form_with(:action => '/search') do |form|
			form.field_with(:name=>'q').value = profile_name
		end.click_button

		profile_page = agent.click(searched_page.link_with(:href => "/#{profile_name}"))
		return profile_page
	end

	def base_followers

	end

	def base_following

	end

end


#class to handle authentication details on twitter.
class Authenticate

	#log in using twitter authentication system
	def initialize(username,password)
		@username = username
		@password = password
		@agent = Mechanize.new

		#mechanize agent setup
		@agent.set_proxy('www-cache.ecs.vuw.ac.nz','8080','jacobtani','tanz1109') #unfortunately I have to hard code uesrnames/passwords into my code.

		#user agent
		user_agent = UserAgent.new
		@agent.user_agent_alias = 'Mac Safari'

		@auth_page = nil

	end

	def authenticate
		puts 'authenticating...'
		@agent.get('https://twitter.com/') do |page|
			puts 'page loaded'

			@auth_page = page.form_with(:action => 'https://twitter.com/signup') do |form| #the form that we need!
				form.field_with(:name => 'user[email]').value = @username
				form.field_with(:name => 'user[user_password]').value = @password
			end.click_button
		end	
		
	end

	def get_agent
		return @agent
	end

	def get_home_page
		if @auth_page == nil then
			authenticate
		else
			return @auth_page
		end
	end

	def reset
		@username = nil
		@pasword = nil
		@agent = nil
		@auth_page = nil
	end

	def set_password password
		@password = password
	end

	def set_user username
		@username = username
	end

end

#first authenticate

auth = Authenticate.new('engr489@gmail.com','smokey12#')
auth.authenticate

#then begin the algorithm..
#current implementation is highly dependant on the username being EXACTLY correct. Therefore pages which I've already fetched are prime candidates.
crawler = Crawler.new('Cmdr_Hadfield',auth.get_agent)
crawler.execute #add arguments for number of pages to scrape, potentially.