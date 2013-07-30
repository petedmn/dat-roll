#class to help with generating user agents
class UserAgent
	def initialize
		#get a random user agent from the user agents file!
		rand_int = rand(8)
		i = 0
		File.open("../helpers/user_agents.txt") do |f|
			f.each_line do |line|
				if i == rand_int
					@user_agent = line
				end
			end
		end
	end

	def get_user_agent
		return @user_agent
	end
end
