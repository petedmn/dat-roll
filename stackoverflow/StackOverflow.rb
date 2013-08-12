require "open-uri"
require "rest-client"
require "crack"
require "hpricot"
require "nokogiri"
require "uri"
require 'openssl'
require "logger"
require './StackUserList'

class StackOverFlow
	def initialize
		@base_url = "http://stackoverflow.com/"
	end

	def scrape(class_name)
		if class_name == "StackUserList"
			user_list = StackUserList.new
			user_list.scrape_all
		end
	end
end

class CommandLineInterface
	def initialize
		set_proxy
		get_instruction
	end

	#get an instruction!
	def get_instruction
		puts "Please input an instruction"
		puts "1 = scrape user list"
		input = STDIN.gets
		if input == "1"
			scrape_user_list
		else
			puts "input:"+input+" is not a valid option. Please try again."
			get_instruction
		end
	end

	def scrape_user_list
		overflow = StackOverFlow.new
		overflow.scrape("StackUserList")
	end

	def set_proxy(proxyname=nil,user=nil,password=nil)
		RestClient.proxy = ENV['http_proxy']
	end
end

cli = CommandLineInterface.new