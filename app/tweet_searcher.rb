# coding: utf-8

require 'twitter'

module Zoint
  class TweetSearcher
    INTERVAL_SEC = 10

    def initialize(consumer_key, consumer_secret, access_token, access_secret, keyword, since_id, callback_method)
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key = consumer_key
        config.consumer_secret = consumer_secret
        config.access_token = access_token
        config.access_token_secret = access_secret
      end
      @keyword = keyword
      @since_id = since_id.to_i
      @callback_method = callback_method
    end

    attr_reader :keyword
    attr_reader :since_id

    def run!
      while true do
        run_search
        sleep INTERVAL_SEC
      end
    rescue => e
      puts e
      sleep 5
      retry
    end

    private
    def run_search
      # ※たくさん来るとたぶん取りこぼす気がする
      @client.search(@keyword, result_type: 'recent', since_id: @since_id).to_a.reverse.each do |tweet|
        # retweetは取り除く
        if tweet.retweeted_status.class == Twitter::NullObject
          @callback_method.call(tweet)
          @since_id = tweet.id
        end
      end
    end
  end
end
