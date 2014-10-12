# coding: utf-8

require 'eventmachine'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'redis-objects'
require 'twitter'
require 'slim'
require 'compass'
require 'json'
require 'logger'

require File.dirname(__FILE__) + '/app/redis.rb'
require File.dirname(__FILE__) + '/app/twitter.rb'
require File.dirname(__FILE__) + '/app/tweet_searcher.rb'
require File.dirname(__FILE__) + '/app/websocket.rb'

configure do
  # directory
  set :views, File.dirname(__FILE__) + '/views'
  set :public_folder, File.dirname(__FILE__) + '/public'

  # Redis
  Redis.current = Zoint::RedisManager.connect

  # 合計カウンタ
  total = Redis::Counter.new('total')
  total.value = 0 unless total.value
  today = Redis::Value.new('today')
  today.value = Time.now.day unless today.value

  # Compass
  Compass.configuration do |config|
    config.project_path = File.dirname(__FILE__)
    config.sass_dir = 'views/compass'
  end
  set :scss, Compass.sass_engine_options
end

configure :production do
  require 'newrelic_rpm'
end

before do
  # URLは1つでいい
  redirect 'http://zoint.rutan.info' if request.host == 'zoint.herokuapp.com'
end

# かわいいトップページ
get '/' do
  slim :index, locals: {
    total: Redis::Counter.new('total').value.to_i,
  }
end

# API
get '/zoi.json' do
  {
    total: Redis::Counter.new('total').value.to_i,
    timestamp: Time.now.to_i,
  }.to_json
end

# API
get '/zoi.jsonp' do
  callback_name = (params[:callback] =~ /\A[A-Za-z0-9_]{1,64}\z/) ? params[:callback] : 'callback'
  callback_name + '(' + {
    total: Redis::Counter.new('total').value.to_i,
    timestamp: Time.now.to_i,
  }.to_json + ');'
end

# 404
not_found do
  redirect '/'
end

# CSS
get '/css/all.css' do
  scss :'compass/all'
end
