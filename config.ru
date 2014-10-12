# coding:utf-8

require File.dirname(__FILE__) + '/app.rb'

$stdout.sync = true

use Zoint::WebSocket
run Sinatra::Application
