require 'sinatra'
require 'sinatra/json'
require 'time'


get '/metric/:key/sum' do |key|
  value = metric_count(key)
  json({ value: value })
end

post '/metric/:key' do |key|
  store_metric(key, params[:value].to_i)
  json({})
end

def metric_count key
  file_name = 'database.json'
  data = JSON.parse(File.read(file_name))['metrics']
  current_time = Time.now.utc
  (data[key] || []).reduce(0) do |sum, item|
    created_at = Time.parse(item['created_at'])
    sum += item['value'] if current_time <= (created_at + 60 * 60)
    sum
  end.to_s
end

def store_metric key, value
  record = { value: value, created_at: Time.now.utc }
  file_name = 'database.json'
  data = JSON.parse(File.read(file_name))
  if data.key?('metrics')
    if data['metrics'].key?(key)
      data['metrics'][key] << record
    else
      data['metrics'][key] = [record]
    end
  else
    data = { metrics: { key => [record] } }
  end

  File.open(file_name, 'w') do |f|
    f.puts data.to_json
  end
end
