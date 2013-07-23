require 'logger'

class LogWriter	

	def self.info(message)
		if @debug_log == nil
			@debug_log  = Logger.new('log/debug.log')
		end
		@debug_log .info(message)
	end

	def self.error(message)
		if @error_log == nil
			@error_log = Logger.new('log/error.log')\
		end
		@error_log.error(message)
	end

	def self.debug(message)
		if@test_log == nil
			@test_log = Logger.new('log/test.log')
		end
		@test_log.debug(message)
	end
end
