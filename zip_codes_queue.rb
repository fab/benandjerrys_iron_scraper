require 'iron_mq'
require 'csv'

ironmq = IronMQ::Client.new(:token => params['token'], :project_id => params['project'])
queue = ironmq.queue('zip_codes')
csv = CSV.open('zip_codes.csv').map(&:first)
csv.each do |zip_code|
  queue.post(zip_code)
end
