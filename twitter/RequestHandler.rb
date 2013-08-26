require './UserAgent'

class RequestHandler
	def initialize(url, user_agent=nil)
		@url = url
		@user_agent = user_agent
	end

	def make_request
		if @user_agent == nil
			@user_agent = UserAgent.new			
		end
		resp = RestClient.get(@url,:user_agent => @user_agent.get_user_agent.to_s)
		return resp
	end

end
