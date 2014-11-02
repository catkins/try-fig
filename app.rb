#! /usr/bin/env ruby

require 'redis'
require 'sinatra'
require 'json'
require 'sinatra/json'


configure do
  # doesn't work without this on boot2docker
  set :bind, '0.0.0.0'

  set :server, 'thin'

  redis_host = ENV['REDIS_PORT_6379_TCP_ADDR'] || ENV['REDIS_HOST'] || 'localhost'
  redis_port = ENV['REDIS_PORT_6379_TCP_PORT'] || ENV['REDIS_PORT'] || 6379
  redis_db   = ENV['REDIS_DB'] || 1

  puts "Connecting to redis at #{redis_host}:#{redis_port}/#{redis_db}"

  Redis.current = Redis.new host: redis_host, port: redis_port, db: redis_db
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
