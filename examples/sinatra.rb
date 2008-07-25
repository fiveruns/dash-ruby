require File.dirname(__FILE__) << "/example_helper"

require 'rubygems'
require 'sinatra'

unless defined?($metrics)
  $metrics = Hash.new(0)
end

get '/' do
  $metrics[:requests] += 1
  "Welcome to Sinatra"
end

def fetch(metric, reset = 0)
  returning $metrics[metric] do
    $metrics[metric] = reset
  end
end

def start_dash_once
  @started_dash ||= begin
    dash do |metrics|
      metrics.recipe :ruby
      metrics.counter :requests, "Number of Requests" do
        fetch :requests
      end
    end
    true
  end
end

start_dash_once