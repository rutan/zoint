# coding: utf-8

require 'faye/websocket'
require 'eventmachine'
require 'thread'
require 'json'

Faye::WebSocket.load_adapter('thin')

module Zoint
  class WebSocket
    CHANNEL_NAME = 'zoint'
    KEYWORD = '今日も一日がんばるぞい OR 今日も一日頑張るぞい OR 今日も1日がんばるぞい OR 今日も1日頑張るぞい'

    def initialize(app)
      @app = app
      @clients = []

      # Twitterの監視
      Thread.new do
        begin
          redis = Zoint::RedisManager.connect
          redis_total = Redis::Counter.new('total')
          redis_today = Redis::Value.new('today')
          redis_since = Redis::Value.new('since')
          redis_since.value = ENV['DEFAULT_SINCE'] unless redis_since.value
          twitter = Zoint::TwitterManager.connect

          Zoint::TweetSearcher.new(
            twitter,
            KEYWORD,
            redis_since.value,
            -> (tweet) {
              redis_since.value = tweet.id

              # 日付変更チェック
              day = Time.now.day
              unless day == redis_today.value.to_i
                # 前日の合計数をツイートするぞい！
                before_count = redis_total.value
                EM.defer do
                  try_count = 0
                  begin
                    twitter.update("昨日も一日 #{before_count} Zoi! http://zoint.rutan.info")
                  rescue => e
                    puts e.inspect
                    try_count += 1
                    if try_count < 3
                      sleep (try_count * 5)
                      retry
                    end
                  end
                end

                # リセットする
                redis_total.value = 0
                redis_today.value = day
              end

              # Zoiカウントを増加
              count = redis_total.increment

              # Reidsに配信依頼
              redis.publish(CHANNEL_NAME, {
                count: count,
                name: tweet.user.screen_name,
              }.to_json)
            }
          ).run!
        rescue => e
          puts e
          sleep 5
          retry
        end
      end

      # 配信受付
      Thread.new do
        redis = Zoint::RedisManager.connect
        begin
          redis.subscribe(CHANNEL_NAME) do |on|
            on.message do |channel, obj_str|
              @clients.each do |ws|
                ws.send(obj_str) if ws
              end
            end
          end
        rescue => e
          puts e
          sleep 5
          retry
        end
      end
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: 15})

        ws.on :open do |event|
          @clients << ws
        end

        ws.on :close do |event|
          @clients.delete(ws)
          @clients.compact!
          ws = nil
        end

        ws.rack_response
      else
        @app.call(env)
      end
    end
  end
end
