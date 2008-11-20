# require File.dirname(__FILE__) << "/test_helper"
# require 'thread'
# require 'rubygems'
# require 'mongrel'
# require 'json'
# require 'thin'
# 
# class Integer
#   def intervals
#     self * 5 + 0.1
#   end
# end
# 
# module Fiveruns::Dash::Store::HTTP
#   def check_response_of(response)
#     unless response
#       Fiveruns::Dash.logger.debug "Received no response from Dash service"
#       return false
#     end
#     case response.code.to_i
#     when 201
#       true
#     when 400..499
#       Fiveruns::Dash.logger.warn "Could not access Dash service (#{response.code.to_i}, #{response.body.inspect})"
#       false
#     else
#       Fiveruns::Dash.logger.debug "Received unknown response from Dash service (#{response.inspect})"
#       false
#     end
#   rescue JSON::ParserError => e
#     puts response.body
#     Fiveruns::Dash.logger.error "Received non-JSON response (#{response.inspect})"
#     false
#   end
# end
# 
# class DummyCollector
#   
#   attr_accessor :sleep_time, :data_payload_count, :info_payload_count, :post_times
#   
#   def initialize(options = {})
#     @startup_delay = options[:startup_delay]
#     @response_delay = options[:response_delay]
#     @info_payload_count = 0
#     @data_payload_count = 0
#     @post_times = []
#   end
# 
#   def call(t)
#     sleep(@sleep_time) if @sleep_time
#     puts "sleeping for #{@sleep_time}" if @sleep_time
#     @post_times << Time.now
#     res = nil
#     if t["rack.input"].read =~ /name=\"type\"\r\n\r\ninfo\r\n/
#       @info_payload_count += 1
#       res = info_response
#     else
#      @data_payload_count += 1
#      res = data_response
#     end
#     puts "BOOM! workers: info: #{@info_payload_count} data: #{@data_payload_count} #{Time.now} - #{Time.now.to_f}"
#     return [201, {"Content-Type" => "application/json; charset=utf-8" }, res]
#   end
# 
#    
#   def info_response
#     data = {"process_id"=>774736468, "metric_infos"=>[{"name"=>"vsz", "id"=>932254202, "recipe_name"=>"ruby", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"rss", "id"=>932254199, "recipe_name"=>"ruby", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"pmem", "id"=>932254200, "recipe_name"=>"ruby", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"cpu", "id"=>932254201, "recipe_name"=>"ruby", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"activity", "id"=>932254194, "recipe_name"=>"activerecord", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"response_time", "id"=>932254195, "recipe_name"=>"actionpack", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"requests", "id"=>932254196, "recipe_name"=>"actionpack", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"render_time", "id"=>932254197, "recipe_name"=>"actionpack", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"queue_size", "id"=>932254198, "recipe_name"=>"rails", "recipe_url"=>"http://dash.fiveruns.com"}], "traces"=>[]}
#     return data.to_json
#   end
#   def data_response
#    data = {"process_id"=>774736448, "metric_infos"=>[{"name"=>"rss", "id"=>932254199, "recipe_name"=>"ruby", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"pmem", "id"=>932254200, "recipe_name"=>"ruby", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"cpu", "id"=>932254201, "recipe_name"=>"ruby", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"activity", "id"=>932254194, "recipe_name"=>"activerecord", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"response_time", "id"=>932254195, "recipe_name"=>"actionpack", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"requests", "id"=>932254196, "recipe_name"=>"actionpack", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"render_time", "id"=>932254197, "recipe_name"=>"actionpack", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"queue_size", "id"=>932254198, "recipe_name"=>"rails", "recipe_url"=>"http://dash.fiveruns.com"}], "traces"=>[]}
#    return data.to_json
#   end
# end
# 
# 
# class CollectorCommunicationTest < Test::Unit::TestCase
#   
#   attr_reader :payload
#   context "FiveRuns Dash Gem" do
# 
#     setup do
#       no_recipe_loading!
#       mock_configuration!
#       create_session!
#       flexmock(@configuration).should_receive(:options).and_return(:app => '123')
#       flexmock(::Fiveruns::Dash).should_receive(:configuration).and_return(@configuration)
#       flexmock(@session.reporter).should_receive(:update_locations).returns(["http://localhost:9999"])
#       #@session.reporter.instance_variable_set :@update_locations, ["http://localhost:9999"]      
#       #flexmock(Fiveruns::Dash::Update).any_instance.should_receive(:check_response_of).returns(true)
#       Thread.abort_on_exception = true
#       
#       @collector = DummyCollector.new()
#       @thin = Thin::Server.new('127.0.0.1', 9999, @collector)
#     end
#     
#     should "act properly" do
#       # When the reporter starts, it immediately sends an info packet,
#       # along with a regular payload
#       @t = Thread.new { @thin.start }
#       @session.reporter.interval = 5
#       @session.reporter.start
#       sleep(2.intervals) #enough for 2 cycles
#       assert_equal @collector.info_payload_count, 1
#       assert_equal @collector.data_payload_count, 2
#       @thin.stop     
#       assert_equal @collector.post_times.size, 3 
#       @collector.post_times.size.times do |i|
#         unless i == (@collector.post_times.size - 1)
#           assert_equal (@collector.post_times[i+1].to_i - @collector.post_times[i].to_i), 5
#         end  
#       end
#       @thin.stop!      
#       sleep(31)
#       
#     end
#     
#     should "compensate correctly for delayed post times" do
#       @collector.sleep_time = 2
#       @t = Thread.new { @thin.start }
#       @session.reporter.interval = 5
#       @session.reporter.start
#       sleep(2.intervals + @collector.sleep_time ) #enough for 2 cycles
#       assert_equal @collector.info_payload_count, 1
#       assert_equal @collector.data_payload_count, 2
#       @thin.stop    
#       assert_equal @collector.post_times.size, 3   
#       @collector.post_times.size.times do |i|
#         unless i == (@collector.post_times.size - 1)
#           assert_equal (@collector.post_times[i+1].to_i - @collector.post_times[i].to_i), 5
#         end  
#       end
#       @thin.stop!    
#       sleep(31)
#               
#     end
#     
#     should "continue to report if the first payload fails" do
#       @session.reporter.interval = 5
#       @session.reporter.start
#       sleep(1.intervals)
#       assert_equal @collector.data_payload_count, 0
#       assert_equal @collector.data_payload_count, 0
#       #puts "STARTING COLLECTOR #{Time.now}"
#       @t = Thread.new { @thin.start }
#       #puts "COLLECTOR STARTED #{Time.now} - #{Time.now.to_f}"
#       #puts "STARTING SLEEP #{Time.now} - #{Time.now.to_f}"
#       sleep(2.intervals)
#       #puts "DONE SLEEPING #{Time.now} - #{Time.now.to_f}"
#       assert_equal @collector.info_payload_count, 1
#       assert_equal @collector.data_payload_count, 1
#       @thin.stop!  
#       sleep(31)
#          
#     end
#   
#     should "continue to report if collector dies at a random time" do
#       @t = Thread.new { @thin.start }
#       @session.reporter.interval = 5
#       @session.reporter.start
#       sleep(2.intervals)
#       @thin.stop
#       assert_equal @collector.info_payload_count, 1
#       assert_equal @collector.data_payload_count, 2
#       sleep(3.intervals) #stop for a while
#       @thin.start
#       sleep(3.intervals)
#       @thin.stop
#       assert_equal @collector.data_payload_count, 5
#       
#       # check the post time intervals to make sure they match what we expect
#       (0..1).each do |i|
#         assert_equal((@collector.post_times[i+1].to_i - @collector.post_times[i].to_i), 5)
#       end  
#       # because we shut down for 3 intervals, the next post wouldn't happen until the 4th interval
#       # thus, 20 seconds
#       assert_equal (@collector.post_times[3].to_i - @collector.post_times[2].to_i), 20 
#       (3..4).each do |i|
#         assert_equal((@collector.post_times[i+1].to_i - @collector.post_times[i].to_i), 5)
#       end
#       @thin.stop!
#       sleep(31)
#       
#     end
#     
#   end
#   
#   
#   #######
#   private
#   #######
#   
#   def full_urls(service)
#     full_uris(service).map(&:to_s)
#   end
#   
#   def full_uris(service)
#     @urls.map do |url|
#       uri = URI.parse(url)
#       uri.path = if service == :exceptions
#         '/exceptions.json'
#       else
#         "/apps/123/#{service}.json"
#       end
#       uri
#     end
#   end
# 
#   def uris
#     @urls.map { |url| URI.parse(url) }
#   end
#   
# end
