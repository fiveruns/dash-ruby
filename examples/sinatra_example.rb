require File.dirname(__FILE__) << "/example_helper"

require 'rubygems'

require 'sinatra'

unless defined?($metrics)
  $metrics = Hash.new(0)
end

p :ok

get '/' do
  $metrics[:requests] += 1
  "Welcome to Sinatra"
end

get '/blowup' do
  raise 'b0rk!!'
end

def fetch(metric, reset = 0)
  returning $metrics[metric] do
    $metrics[metric] = reset
  end
end

def start_dash_once
  @started_dash ||= begin
    dash do |metrics|
      metrics.add_recipe :ruby
      metrics.counter :requests, "Number of Requests" do
        fetch :requests
      end
      metrics.add_exceptions_from 'Sinatra::Application#run_safely'
    end
    true
  end
end

start_dash_once