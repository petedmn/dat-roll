require 'nokogiri'
require 'mechanize'
require 'rest-client'
require 'json'
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
		
		#load base_followers
		base_followers(@agent,@profile_name)

		#load base_following
		base_following(@agent,@profile_name)
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

	#return a list of the profiles of everyone who follows this person.
	def base_followers(agent,profile_name)
		follower_names = Array.new		
		followers_page = agent.click(agent.page.link_with(:href => "/#{profile_name}/followers"))
		
		#Now use RestClient in order to do some manual manipulation of cookies.

		#fetch the authentication token from agent's cookies.
		#It is somewhat of a struggle to get the first cookies into good representation, but after that it is a breeze.
		auth_token = nil		
		agent.cookies.each do |val|
			if(val.to_s.start_with? 'auth_token') then
				auth_token = val.to_s.gsub("auth_token=", "")
			end
		end			

		response = RestClient.get(followers_page.uri.to_s,
									{:cookies => {:auth_token => auth_token.to_s,:secure_session => "true"}})
		#now loop over some rest-client requests, at each step parsing the response.

		#so parse the profiles which are available at the base level.
		doc = Nokogiri::HTML(response)
		profiles_xpath = '//*[@id="stream-items-id"]/li'
		doc.xpath(profiles_xpath).each do |node|
			name_xpath = './div/div[2]/div/a/@href'
			#remove the '/' character
			name = node.xpath(name_xpath).to_s.gsub("/","")
			follower_names << name			
		end		

		#ok we have all of the profiles available at this base level. Now, need to deal with inifinite scroll.		
		#the data cursor is a value that is necessary when dealing with 
		data_cursor_xpath = '//*[@id="timeline"]/div[2]/@data-cursor'
		data_cursor = doc.xpath(data_cursor_xpath).to_s
		puts "data cursor #{data_cursor}"
		
		has_more = true
		until has_more == false do
			has_more = parse_extra_followers(data_cursor,profile_name,follower_names,auth_token)
		end		

		return follower_names	
	end

	#helper method to parse the extra followers, from a given json response from twitter.
	def parse_extra_followers(data_cursor_val,profile_name,follower_names,auth_token)
		#the URI... Magic, really. If this changes, all must change accordingly! We worship this URI! (pls don't change this, Twitter.)
		uri = "https://twitter.com/#{profile_name}/followers/users?cursor=#{data_cursor_val}&include_available_features=1&include_entities=1&is_forward=true"
		response = RestClient.get(uri,
									{:cookies => {:auth_token => auth_token.to_s,:secure_session => "true"}})

		json = JSON.parse(response)
		file = File.open('auth_page.html','w')
		file.write(json)
		file.close
		#puts JSON.parse(response)
	#	https://twitter.com/Cmdr_Hadfield/followers/users?cursor=1347834627953995830&include_available_features=1&include_entities=1&is_forward=true

		return false
	end

	#return a list of the profiles of everyone who this person is following.
	def base_following(agent,profile_name)
		following_names = Array.new
		following_page = agent.click(agent.page.link_with(:href => "/#{profile_name}/following"))
		following_page.links.each do |link|

		end
		return following_names
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