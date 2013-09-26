require 'iron_mq'
require 'csv'

ironmq = IronMQ::Client.new(:token => params['token'], :project_id => params['project'])
queue = ironmq.queue('zip_codes')
csv = CSV.open('zip_codes.csv').map(&:first)
messages = []
csv.each do |zip_code|
  messages << {:body => zip_code, :expires_in => 2592000}
end
queue.post(messages)
