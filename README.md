The place where I store my web-scraping code for my 2013 honours project. Seperate 
folders for each website that I am interested in scraping data from. 

TODO: - remove results from the repository
      - refactor framework
      - database integration with ActiveRecord
      - look into bugs with fetching profiles
      - setup more adequate testing
      - remove command line argument parsing, change to a config file

USAGE

To use the Twitter scraper, you call the scraper like:

ruby Twitter.rb 'NAME_FILE' 'RESULTS_DIR'

Where NAME_FILE contains a list of names to be searched for on Google and RESULTS_DIR
is a directory where you want your results to be saved to. 

