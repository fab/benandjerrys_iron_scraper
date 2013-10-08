require_relative 'development/iron_scraper_dev.rb' unless ARGV.include?('-id')
require 'mechanize'
require 'csv'
require 'pg'
require 'active_record'
require 'iron_mq'

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

def create_zip_code_array
  zip_codes = []
  ironmq = IronMQ::Client.new(:token => params['token'], :project_id => params['project'])
  queue = ironmq.queue('zip_codes')
  messages = queue.get(:n => 5)
  messages.each do |message|
    zip_codes << message.body
    message.delete
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
  begin
    store.flavors << flavor unless store.flavors.include?(flavor)
  rescue ActiveRecord::RecordNotUnique
    puts "Uniqueness constraint has trigged an error. No action needed."
  end
end

def iterate_over_flavors(flavor_options)
  flavors = flavor_options[4..8] + flavor_options[12..-16]
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

def run_scraper
  setup
  zip_codes = create_zip_code_array
  iterate_over_zip_codes(zip_codes)
  Store.where("created_at > ?", @start_time).each do |store|
    puts "#{store.name}, #{store.address}, #{store.flavors.map(&:name).join(', ')}"
  end
end

run_scraper
