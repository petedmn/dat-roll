class CreateTweets < ActiveRecord::Migration

	def self.up
		create_table :profiles do |t|
			t.column :username, :string, :null => false
			t.column :number_followers, :integer, :null => false
			t.column :number_tweets, :integer, :null => false
			t.column :number_following, :integer, :null => false
		end

		create_table :tweets do |t|
			t.column :tweet_content, :string, :null => false
			t.column :retweet_count, :integer, :null => false
			t.column :favourite_count, :integer, :null => false
			t.column :profile_id, :integer, :null => false
		end
	end

	def self.down
		drop_table :tweets
		drop_table :profiles
	end

end