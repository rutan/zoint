# encoding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

describe 'App' do
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end

  describe 'GET /' do
    before :each do
      mock = double('Redis', value: 100)
      allow(Redis::Counter).to receive(:new).with('total').and_return(mock)
    end

    subject do
      get '/'
      last_response
    end

    it 'ステータスコード200を返すこと' do
      expect(subject.status).to be 200
    end

    it '合計値が渡されること' do
      expect(subject.body).to include 'data-value="100"'
    end
  end

  describe 'GET /zoi.json' do
    before :each do
      mock_redis = double('Redis', value: 123)
      allow(Redis::Counter).to receive(:new).with('total').and_return(mock_redis)
      mock_time = double('Time', to_i: 1406247638)
      allow(Time).to receive(:now).and_return(mock_time)
    end

    subject do
      get '/zoi.json'
      last_response
    end

    it 'ステータスコード200を返すこと' do
      expect(subject.status).to be 200
    end

    it '合計値とタイムスタンプが渡されること' do
      json = JSON.parse(subject.body)
      expect(json['total']).to be 123
      expect(json['timestamp']).to be 1406247638
    end
  end

  describe 'GET /zoi.jsonp' do
    before :each do
      mock_redis = double('Redis', value: 123)
      allow(Redis::Counter).to receive(:new).with('total').and_return(mock_redis)
      mock_time = double('Time', to_i: 1406247638)
      allow(Time).to receive(:now).and_return(mock_time)
    end

    subject do
      get '/zoi.jsonp', callback: callback_name
      last_response
    end

    context 'callback_nameを指定しないとき' do
      let(:callback_name) { nil }

      it 'ステータスコード200を返すこと' do
        expect(subject.status).to be 200
      end

      it 'コールバック名が callback であること' do
        expect(subject.body).to include 'callback'
      end
    end

    context '正常なcallback_nameを指定したとき' do
      let(:callback_name) { 'my_callback123' }

      it 'ステータスコード200を返すこと' do
        expect(subject.status).to be 200
      end

      it 'コールバック名が指定したものであること' do
        expect(subject.body).to include callback_name
      end
    end

    context '不正なcallback_nameを指定したとき' do
      let(:callback_name) { 'コールバック' }

      it 'ステータスコード200を返すこと' do
        expect(subject.status).to be 200
      end

      it 'コールバック名が callback であること' do
        expect(subject.body).to include 'callback'
      end
    end
  end
end
