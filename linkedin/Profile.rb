require 'rest-client'
require 'nokogiri'
require 'work_queue'

class Profile

	def initialize
		
	end

	def scrape

	end

end

class LinkedInItem
	def initialize(content,raw)
		@raw = raw
		@content = content		
	end

	def write_to_file(file_name,directory_name)
		begin
			Dir::mkdir(directory_name)
		rescue Exception=>e
		end

		file = File.open(directory_name+"/"+file_name,"w")
		file.write(@raw.to_s)
		file.close
	end
end