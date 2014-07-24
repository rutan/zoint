# coding: utf-8

require 'sinatra'
require 'rack/test'
require 'rspec'

set :environment, :test
set :run, false

require File.dirname(__FILE__) + '/../app.rb'
