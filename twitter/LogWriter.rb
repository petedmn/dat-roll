require 'logger'

class LogWriter	

	#use for debugging/general
	def self.info(message)
		if @debug_log == nil
			@debug_log  = Logger.new('log/debug.log')
		end
		@debug_log .info(message)
	end

	#use for error logging
	def self.error(message)
		if @error_log == nil
			@error_log = Logger.new('log/error.log')\
		end
		@error_log.error(message)
	end


	#use for debugging
	def self.debug(message)
		if@test_log == nil
			@test_log = Logger.new('log/test.log')
		end
		@test_log.debug(message)
	end

	#use for testing/performance
	def self.test(message)
		if @test_logger == nil
			@test_logger = Logger.new('log/test_logger.log')
		end
		@test_logger.debug(message)
	end

	#using for performance logging
	def self.performance(message)
		if @performance_log == nil
			@performance_log = Logger.new('log/performance.log')
		end
		@performance_log.debug(message)
	end

	#using for tweet parse time logging
	def self.parse_performance(message)
		if @parse_performance_log == nil
			@parse_performance_log = Logger.new('log/parse_performance.log')
		end
		@parse_performance_log.debug(message)
	end

	#using for fetch time logging
	def self.fetch_performance(message)
		if @fetch_performance_log == nil
			@fetch_performance_log = Logger.new('log/fetch_performance.log')
		end
		@fetch_performance_log.debug(message)
	end

	#using for reliability logging
	def self.failure_log(message,run=nil,name=nil)
		if @fail_log == nil
			@fail_log = Logger.new('log/failure.log')
		end
		@fail_log.error(message)
		if run != nil
			@fail_log.info(run)
		end
		if name != nil
			@fail_log.info(name)
		end
	end

end
