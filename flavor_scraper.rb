require_relative 'development/flavor_scraper_dev.rb' unless ARGV.include?('-id')
require 'mechanize'
require 'pg'
require 'active_record'

require './models/flavor.rb'

def setup
  @agent = Mechanize.new
  setup_database
end

def setup_database
  return unless params['database']
  puts "Database connection details: #{params['database'].inspect}"
  ActiveRecord::Base.establish_connection(params['database'])
end

def flavor_indexes
  (0..38).to_a + (43..49).to_a
end

def iterate_over_flavor_indexes(flavor_indexes)
  flavor_indexes.each do |flavor_index|
    @flavor_list = get_page(flavor_index)

    (flavor_index < 10 or flavor_index > 42) ? @flavor_page = @flavor_list.links[2].click : @flavor_page = @flavor_list.links[3].click

    create_or_modify_flavor_entry(flavor_name, description, ingredients, img_url)
    log_flavor_attributes_to_console(flavor_name, description, ingredients, img_url)
  end
end

def get_page(flavor_index)
  @agent.get("http://m.benjerry.com/flavors?packageType=2&startIndex=#{flavor_index}")
end

def flavor_name
  @flavor_page.search('h2').first.text
end

def description
  @flavor_page.search('p').first.text
end

def ingredients
  ingredients_string = @flavor_page.search('p')[1].text.slice(/(?<=:).*/).gsub('*', '')
  format_ingredients_string(ingredients_string)
end

def img_url
  "http://www.benjerry.com" + @flavor_page.search('.productImage').attr('src').value
end

def format_ingredients_string(ingredients_string)
  ingredients_array = ingredients_string.split(/\s/).map(&:downcase)
  ingredients_array.delete('')
  ingredients_array.each do |ingredient|
    (ingredient[0] == "(" or ingredient[0] ==  "[") ? ingredient[1] = ingredient[1].upcase : ingredient[0] = ingredient[0].upcase
  end
  ingredients_array.join(' ')
end

def create_or_modify_flavor_entry(flavor_name, description, ingredients, img_url)
  flavor = Flavor.where(:name => flavor_name).first_or_create
  flavor.update(:description => description, :ingredients => ingredients, :img_url => img_url)
end

def log_flavor_attributes_to_console(flavor_name, description, ingredients, img_url)
  puts "Flavor name: #{flavor_name}"
  puts "Description: #{description}"
  puts "Ingredients: #{ingredients}"
  puts "Img url: #{img_url}"
end

def run_scraper
  setup
  iterate_over_flavor_indexes(flavor_indexes)
end

run_scraper

