# coding: utf-8

require 'redis'

module Zoint
  module RedisManager
    def self.connect
      if ENV['REDISCLOUD_URL']
        uri = URI.parse(ENV['REDISCLOUD_URL'])
        Redis.new(host: uri.host, port: uri.port, password: uri.password)
      else
        Redis.new(host: '127.0.0.1', port: 6379)
      end
    end
  end
end
