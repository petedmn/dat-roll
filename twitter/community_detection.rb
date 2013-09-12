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
		#remember to set the RestClient proxy
		set_proxy
	end	 

	#we need to loop through profiles, and gather follower/following details for these profiles
	#this is kind of the main method for our crawler.

	#then, we can go through tweets and look at who is retweeting these. 
	def execute(num_profiles=0,current_level=0) #might start using number of profiles as an argument later;not needed at this point.	

		#first, load the base profile.
		page = search_page(@agent,@profile_name)

		#load base_following
		following_names = base_following(@agent,@profile_name)
		
		#go back..
		@agent.back

		#load base_followers
		follower_names = base_followers(@agent,@profile_name) #this will take a while for Cmdr_Hadfield!		

		#save these.
		save(follower_names,following_names,@profile_name)

		#keep going! Lol not yet.
		#By the way this is naturally recursive. 
		unless following_names == nil then
			following_names.each do |name|
				scrape_profile(name,1)
			end
		end

		unless follower_names == nil then
			follower_names.each do |name|
				scrape_profile(name,1)
			end
		end

	 end


	def scrape_profile(name,depth=1,max=1)
		#go back, first off.
		@agent.back

		#first load base profile
		page = search_page(@agent,name)

		#load following
		following_names = base_following(@agent,name)

		@agent.back

		#load followers
		follower_names = base_followers(@agent,name)

		#save this profile
		save(follower_names,following_names,name)

		#keep being recursive!
		unless depth >= max then
			unless following_names == nil then
				following_names.each do |name|
					scrape_profile(name,depth+1,max)
				end
			end

			unless follower_names == nil then
				follower_names.each do |name|
					scrape_profile(name,depth+1,max)
				end
			end
		end

	end


	#set proxy for the uni environment.
	def set_proxy
		RestClient.proxy = ENV['http_proxy']
	end

	#take two arrays of follower names and following names
	def save(follower_names, following_names,profile_name)
		#currently just save to a txt file, this will be changed to database integration at a later date.
			builder = Nokogiri::XML::Builder.new do |xml|
				xml.profile{
					xml.name_ profile_name
						xml.followers{
							unless follower_names == nil then
								follower_names.each do |follower|
									xml.follower_name_ follower
								end
							end
						}
						xml.following{					
						unless following_names == nil then
							following_names.each do |following|
								xml.following_name_ following
							end
						end
					}
				}
			end
			#save to VOL in order to manage my own disk usage.
			xml_str = builder.to_xml

			base_directory = '/vol/projects/kris/OpenRep/Iain/results/community_follower_dataset/'
			file = File.open("#{base_directory}#{profile_name}.xml",'w')
			file.write(xml_str)
			file.close
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

		#do the request.

		response = request(followers_page.uri.to_s,auth_token.to_s,0)

		# response = RestClient.get(followers_page.uri.to_s,
		# 							{:cookies => {:auth_token => auth_token.to_s,:secure_session => "true"}})
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
		@data_cursor = doc.xpath(data_cursor_xpath).to_s
		puts "data cursor #{@data_cursor}"
		
		has_more = true
		until has_more == false do
			has_more = parse_extra_followers(@data_cursor,profile_name,follower_names,auth_token)
		end		

		return follower_names	
	end

	#handle the request, along with a retry counter.
	#this is better as a seperate method, since the same code is written in multiple places.
	#also since it is in a seperate method we can better handle failure.
	def request(url,auth_token,retry_count,max_retries=3)
		begin
			response = RestClient.get(url,
										{:cookies => {:auth_token => auth_token.to_s,:secure_session => "true"}})	
			return response
		rescue Exception => e
			response = request(url,auth_token,retry_count+1,max_retries)
			return response
		end
	end

	#helper method to parse the extra followers, from a given json response from twitter.
	def parse_extra_followers(data_cursor_val,profile_name,follower_names,auth_token)
		#the URI... Magic, really. If this changes, all must change accordingly! We worship this URI! (pls don't change this, Twitter.)
		uri = "https://twitter.com/#{profile_name}/followers/users?cursor=#{data_cursor_val}&include_available_features=1&include_entities=1&is_forward=true"
		puts uri

		response = request(uri,auth_token.to_s,0)

		# response = RestClient.get(uri,
		# 							{:cookies => {:auth_token => auth_token.to_s,:secure_session => "true"}})

		json = JSON.parse(response)

		@data_cursor = json["cursor"]

		has_more = json["has_more_items"]

		items_html = json["items_html"]

		doc = Nokogiri::HTML(items_html)

		doc.xpath('/html/body/li').each do |node|
			name_xpath = './div/div[2]/div/a/@href'
			name = node.xpath(name_xpath).to_s.gsub("/","")
			follower_names << name			 
		end		

		return has_more
	end

	#return a list of the profiles of everyone who this person is following.
	def base_following(agent,profile_name)
		following_names = Array.new
		following_page = agent.click(agent.page.link_with(:href => "/#{profile_name}/following"))
		
		#Need to use RestClient in order to do some manual manipulation of cookies etc.
		auth_token = nil		
		agent.cookies.each do |val|
			if(val.to_s.start_with? 'auth_token') then
				auth_token = val.to_s.gsub("auth_token=", "")
			end
		end			

		# response = RestClient.get(following_page.uri.to_s,
		# 							{:cookies => {:auth_token => auth_token.to_s,:secure_session => "true"}})

		response = request(following_page.uri.to_s,auth_token.to_s,0)
		#now loop over some rest-client requests, at each step parsing the response.		

				#so parse the profiles which are available at the base level.
		doc = Nokogiri::HTML(response)
		profiles_xpath = '//*[@id="stream-items-id"]/li'
		doc.xpath(profiles_xpath).each do |node|
			name_xpath = './div/div[2]/div/a/@href'
			#remove the '/' character
			name = node.xpath(name_xpath).to_s.gsub("/","")
			following_names << name		
		end		

		#ok we have all of the profiles available at this base level. Now, need to deal with inifinite scroll.		
		#the data cursor is a value that is necessary when dealing with 
		data_cursor_xpath = '//*[@id="timeline"]/div[2]/@data-cursor'
		@data_cursor = doc.xpath(data_cursor_xpath).to_s
		puts "data cursor #{@data_cursor}"
		
		has_more = true
		until has_more == false do
			has_more = parse_extra_following(@data_cursor,profile_name,following_names,auth_token)
		end			
		return following_names
	end

	#helper method for the following case. Very similar to followers, could possibly refactor this into a single method.
	def parse_extra_following(data_cursor_val,profile_name,following_names,auth_token)
		#the URI... Magic, really. If this changes, all must change accordingly! We worship this URI! (pls don't change this, Twitter.)
		uri = "https://twitter.com/#{profile_name}/following/users?cursor=#{data_cursor_val}&include_available_features=1&include_entities=1&is_forward=true"
		puts uri
		response = request(uri,auth_token.to_s,0)

		# response = RestClient.get(uri,
		# 							{:cookies => {:auth_token => auth_token.to_s,:secure_session => "true"}})

		json = JSON.parse(response)

		@data_cursor = json["cursor"]

		has_more = json["has_more_items"]
		puts has_more

		items_html = json["items_html"]

		doc = Nokogiri::HTML(items_html)

		doc.xpath('/html/body/li').each do |node|
			name_xpath = './div/div[2]/div/a/@href'
			name = node.xpath(name_xpath).to_s.gsub("/","")
			following_names << name			 
		end		

		return has_more
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

#first command line argument is the file which stores profile names
unless ARGV[0] == nil then
	file_name = ARGV[0]
end

#then begin the algorithm..
#current implementation is highly dependant on the username being EXACTLY correct. Therefore pages which I've already fetched are prime candidates.
crawler = Crawler.new('k_j_gorman',auth.get_agent)
crawler.execute #add arguments for number of pages to scrape, potentially.