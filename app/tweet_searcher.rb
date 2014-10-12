# coding: utf-8

require 'twitter'

module Zoint
  class TweetSearcher
    INTERVAL_SEC = 15

    def initialize(twitter, keyword, since_id, callback_method)
      @client = twitter
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
    rescue Twitter::Error::TooManyRequests => e
      puts "sleep #{e.rate_limit.reset_in}s <- #{e.inspect}"
      sleep e.rate_limit.reset_in
      retry
    rescue => e
      puts "sleep 5s <- #{e.inspect}"
      sleep 5
      retry
    end

    private
    def run_search
      # ※たくさん来るとたぶん取りこぼす気がする
      @client.search(@keyword, result_type: 'recent', since_id: @since_id).to_a.reverse.each do |tweet|
        # retweetは取り除く
        if tweet.retweeted_status.class == Twitter::NullObject
          begin
            @callback_method.call(tweet)
          rescue => e
            puts e.inspect
          end
          @since_id = tweet.id
        end
      end
    end
  end
end
