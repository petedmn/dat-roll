require "open-uri"
require "rest-client"
require "crack"
require "nokogiri"
require "uri"
require 'openssl'
require "logger"
require 'builder'
require './TwitterScraper'
require './TwitterItem'
require './Tweet'
require './UserAgent'
require './RequestHandler'
require './String'
require './LogWriter'

class GoogleTwitterScraper	

	#load a list of names to search
	def initialize(file_name,run_file_name=nil)
		@name_list = []
		@google_remote_base_url = "http://www.google.com/cse?cx=004053080137224009376%3Aicdh3tsqkzy&ie=UTF-8&q="
		load(file_name)
		@run_file_name = run_file_name		
		#puts "begin scraping"
		start_scrape
	end

	def load(file_name)
		File.open(file_name) do |f|
			f.each_line do |line|
				add(line)
			end
		end
	end

	def add(name)
		@name_list << name
	end

	def start_scrape
		 @name_list.each do |name|
			url_list = fetch_twitter_account_url(name)
			scrape_url_list(url_list)
			#pause 30 seconds between scraping requests.
			sleep(30)
		 end		 
	end

	def scrape_url_list(url_list)
		url_list.each do |url|
			begin
			name = url.text().to_s.tap{|s| s.slice!("https://twitter.com/")}
			scraper = TwitterScraper.new(url)
			twitter_item = scraper.scrape
			twitter_item.parse #make sure all mandatory fields are evaluated first
			#puts twitter_item.get_num_tweets
			#puts twitter_item.get_num_followers
			#puts twitter_item.get_num_following
			twitter_item.fetch_tweets
			twitter_item.write_to_file(name+".xml",@run_file_name)
			sleep(20)
			#various exceptions can be thrown here due invalid urls/private twitter accounts
			#that we can't touch. If an exception is recieved back here we just ignore it :)
			rescue Exception => e
				#log the exception
				$logger.info(e)
			end
		end
	end

	#do a twitter google search in order to access the account URL of a given person
	def fetch_twitter_account_url(name)
		#puts "fetching account urls for" + name
		links = []
		
		LogWriter.info "#{Time.now}: INFO start download"		
		resp = RestClient.get(@google_remote_base_url + name)
		LogWriter.info "#{Time.now}: INFO end download"
		doc = Nokogiri::HTML(resp)

		(1..1).each do |i|
		#(1..11).each do |i|
			xpath = '/html/body/div[2]/div/ol/li['+ (i.to_s)+']/div/a/@href' #this is the url to the person's twitter profile(magic)
   			link_to_investigate = (doc.xpath(xpath))
   			links[i-1] = link_to_investigate
   			#puts links[i-1]
		 end
		 return links
	end
end

class CommandLineInterface
	def initialize
		LogWriter.new		
		LogWriter.info("this is a test")
	end
		
	def start(filename,run_dir_name)
		@name_list = GoogleTwitterScraper.new(filename,run_dir_name)
	end

	def set_proxy(proxyname=nil,user=nil,password=nil)
		RestClient.proxy = ENV['http_proxy']
	end
end

cli = CommandLineInterface.new
cli.set_proxy

#sanity checking
if ARGV[0] == nil
	puts "Error - please enter a file to load names from"
	puts "Usage - ruby Twitter.rb NAME_FILE_LOCATION RESULTS_DIRECTORY_LOCATION"
	exit
end

if ARGV[1] == nil
	puts "Error - please enter a directory to save results to"
	puts "Usage - ruby Twitter.rb NAME_FILE_LOCATION RESULTS_DIRECTORY_LOCATION"
	exit
end

if ARGV[0]
	filename = ARGV[0]
	run_file_name = ARGV[1]
puts "run file name:"+run_file_name
   cli.start(filename,run_file_name)
else
   cli.start("helpers/names.txt")
end

