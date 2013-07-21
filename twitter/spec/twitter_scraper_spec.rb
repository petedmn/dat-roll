require_relative '../TwitterScraper'
require 'yaml'
require 'spec_helper'

#let's do some tests
describe TwitterScraper do
	@url = 'https://twitter.com/cmdr_hadfield'
	before do
		@twitter_scraper = TwitterScraper.new(@url)
	end

	it "should have the valid url" do
		@twitter_scraper.@url == @url
	end

	it "should have the correct name" do
		@twitter_scraper.@name == "cmdr_hadfield"
	end	
end
