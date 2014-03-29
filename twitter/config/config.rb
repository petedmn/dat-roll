require 'mixlib/config'

module MyConfig
	extend Mixlib::Config
	config_strict_mode true
	default :name_list_file, './helpers/names.txt'
	default :user_agents_file, './helpers/user_agents.txt'
	default :google_search_url, 'http://www.google.com/cse?cx=004053080137224009376%3Aicdh3tsqkzy&ie=UTF-8&q='
end