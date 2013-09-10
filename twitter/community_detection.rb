require 'nokogiri'
require 'mechanize'
require 'rest-client'
require_relative './UserAgent'


class Crawler

	#we start with a given profile. 
	#profile_name = the profile to start with
	#home page is the mechanize representation of the authenticated home page.
	def initialize(profile_name,home_page)
		@profile_name = profile_name
		@home_page = home_page 
	end	 

	#we need to loop through profiles, and gather follower/following details for these profiles

	#then, we can go through tweets and look at who is retweeting these. 

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
		#rest_client = RestClient.new
		#RestClient.get('http://www.google.com')
		@agent.get('https://twitter.com/') do |page|
			puts 'page loaded'

			@auth_page = page.form_with(:action => 'https://twitter.com/signup') do |form| #the form that we need!
				puts form.action
				form.fields.each do |field|
					puts field.name					
				end
				form.field_with(:name => 'user[email]').value = @username
				form.field_with(:name => 'user[user_password]').value = @password
			end.click_button
		end	
		
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
crawler = Crawler.new('cmdrhadfield',auth.get_home_page)