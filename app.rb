#! /usr/bin/env ruby

require 'redis'
require 'sinatra'
require 'json'
require 'sinatra/json'


configure do
  # doesn't work without this on boot2docker
  set :bind, '0.0.0.0'

  set :server, 'thin'


  redis_options = {
    host: ENV['REDIS_PORT_6379_TCP_ADDR'] || ENV['REDIS_HOST'] || 'localhost',
    port: ENV['REDIS_PORT_6379_TCP_PORT'] || ENV['REDIS_PORT'] || 6379,
    db: ENV['REDIS_DB'] || 1
  }

  if ENV['REDIS_PASSWORD']
    redis_options[:password] = ENV['REDIS_PASSWORD']
  end

  puts "Connecting to redis at #{redis_options[:host]}:#{redis_options[:port]}/#{redis_options[:db]}"

  Redis.current = Redis.new redis_options
end

helpers do
  def redis
    Redis.current
  end
end

get '/' do
  ip_address = request.ip
  logger.info "Request from #{ip_address}"
  logger.info "#{redis.hgetall(:unique_visitors)}"
  count = redis.hincrby :unique_visitors, ip_address.to_s, 1
  visitors = redis.hgetall(:unique_visitors).map do |ip, visit_count|
    { ip_address: ip, visit_count: visit_count}
  end

  json visitors: visitors, time: Time.now.to_i
end
