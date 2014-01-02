Ben & Jerry's Iron.io Scraper
=============================
This web scraper uses [iron.io](http://iron.io) to generate a database of store locations for [Ben & Jerry's](http://www.benjerry.com) ice cream flavors. There is also a scraper that obtains detailed information about each of the flavours. Together, these two scrapers provide the data for the [Ben & Jerry's API](https://github.com/fab/benandjerrys_api).

The Iron.io scraper is based on the original [Ben & Jerry's scraper](https://github.com/fab/benandjerrys_scraper).

## Running the Scraper Locally
- Install the Ruby gem dependencies: ```mechanize```, ```pg```, ```active_record``` (included with Rails) and ```iron_mq```.
- Create a message queue on [IronMQ](http://iron.io/mq) with the zip codes you want to scrape data for.
- Get the Token and Project ID from [iron.io](http://iron.io) and set them as ```ENV['IRON_TOKEN']``` and ```ENV['IRON_PROJECT_ID']```.
- Rename ```database.yml.example``` to ```database.yml``` and replace ```development``` values with those of [your Heroku database](https://postgres.heroku.com/databases).
- Then run this script from your terminal: ```development/run_scraper_locally```
