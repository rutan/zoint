# coding:utf-8

require File.dirname(__FILE__) + '/app.rb'

use Zoint::WebSocket
run Sinatra::Application
