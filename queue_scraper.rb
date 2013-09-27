require 'iron_worker_ng'

def database_config
  YAML.load(File.read('database.yml'))
end

client = IronWorkerNG::Client.new
500.times do |i|
  client.tasks.create('scraper', {:token => ENV['IRON_TOKEN'],
                                :project => ENV['IRON_PROJECT_ID'],
                                :database => database_config['production']})
  puts "Queued scraper task number #{i}"
end
