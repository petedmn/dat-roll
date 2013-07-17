class RequestHandler
	def initialize(url, user_agent)
		@url = url
		@user_agent = user_agent
	end

	def make_request
		resp = RestClient.get(@url,:user_agent => @user_agent.get_user_agent.to_s)
		return resp
	end

end
