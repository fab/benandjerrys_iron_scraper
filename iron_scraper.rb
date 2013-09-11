require_relative 'iron_scraper_dev.rb' unless ARGV.include?('-id')
require 'mechanize'
require 'csv'
require 'pg'
require 'active_record'

require './models/store.rb'
require './models/flavor.rb'

def setup
  @agent = Mechanize.new
  @agent.idle_timeout = 1
  @page = @agent.get('http://m.benjerry.com/flavor-locator')
  @flavor_form = @page.forms.first
  @start_time = Time.now
  setup_database
end

def setup_database
  return unless params['database']
  puts "Database connection details: #{params['database'].inspect}"
  ActiveRecord::Base.establish_connection(params['database'])
end

def create_zip_code_array(filename, start_num, end_num)
  zip_codes = []
  csv = CSV.read(filename)
  csv[start_num..end_num].each do |zip_code|
    zip_codes << zip_code.first
  end
  p zip_codes
end

def store_entry?(link)
  link.href.include?('google')
end

def iterate_over_links(page, flavor_name)
  return if page.search('h3').text == 'Sorry...No Results Found.'
  page.links.each_with_index do |link, index|
    break if link.href == nil
    if store_entry?(link)
      store_details = link.text.strip.gsub("\r\n", '').squeeze("\t").split("\t")
      create_or_modify_store_entry(store_details, flavor_name)
    end
  end
end

def create_or_modify_store_entry(store_details, flavor_name)
  name = store_details.first
  street = store_details[1]
  city = store_details[2].slice(/\D+/)[0..-2]
  zip = store_details[2].slice(/\d+/)

  store = Store.where(:address => "#{street}, #{city} #{zip}").first_or_create
  store.update_attribute(:name, name)

  flavor = Flavor.where(:name => flavor_name).first_or_create
  store.flavors << flavor unless store.flavors.include?(flavor)
end

def iterate_over_flavors(flavor_options)
  flavors = flavor_options[5..9] + flavor_options[11..-19]
  flavors.each do |flavor_option|
    @selectlist.value = flavor_option.value
    flavor_name = flavor_option.text.slice(/(?<=- ).*/)
    puts "Now scraping data for: #{flavor_name}"
    page = @agent.submit(@flavor_form)
    iterate_over_links(page, flavor_name)
  end
end

def iterate_over_zip_codes(zip_codes)
  total_zip_codes = zip_codes.length
  zip_codes.each_with_index do |zip_code, index|
    @flavor_form.locatorZip = zip_code
    puts "Scraping stores for zip code (#{index + 1}/#{total_zip_codes}): #{zip_code}"
    @selectlist = @flavor_form.field_with(:name => "locatorFlavor_r")
    flavor_options = @selectlist.options
    iterate_over_flavors(flavor_options)
  end
end

def ensure_unique_flavors(uniq_stores)
  uniq_stores.each do |k, v|
    uniq_stores[k].uniq!
  end
end

def run_scraper(zip_codes_filename)
  setup
  zip_codes = create_zip_code_array(zip_codes_filename, params['start'], params['end'])
  iterate_over_zip_codes(zip_codes)
  Store.where("created_at > ?", @start_time).each do |store|
    puts "#{store.name}, #{store.address}, #{store.flavors.map(&:name).join(', ')}"
  end
end

run_scraper('zip_codes.csv')
