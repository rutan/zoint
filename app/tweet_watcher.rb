# coding: utf-8

require 'twitter'

module Zoint
  # StreamingAPIで指定ワード検索する子
  # StreamingAPIが日本語を理解してくれる日まで永眠(´・ω・｀)
  class TweetWatcher
    def initialize(consumer_key, consumer_secret, access_token, access_secret, keywords, callback_method)
      @client = Twitter::Streaming::Client.new do |config|
        config.consumer_key = consumer_key
        config.consumer_secret = consumer_secret
        config.access_token = access_token
        config.access_token_secret = access_secret
      end
      @keywords = keywords.join(',')
      @callback_method = callback_method
    end

    def run!
      @client.filter(track: @keywords) do |obj|
        @callback_method.call(obj) if obj.is_a?(Twitter::Tweet)
      end
    rescue => e
      puts e
      sleep 5
      retry
    end
  end
end
