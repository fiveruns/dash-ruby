require File.dirname(__FILE__) << "/test_helper"
require 'thread'
require 'rubygems'
require 'mongrel'
require 'json'

class DummyCollector < Mongrel::HttpHandler
  
  attr_accessor :sleep_time, :data_payload_count, :info_payload_count, :mongrel
  
  def initialize(options = {})
    @startup_delay = options[:startup_delay]
    @response_delay = options[:response_delay]
    @info_payload_count = 0
    @data_payload_count = 0
  end
  
  def stop
    puts "SHUTTING DOWN"
    @mongrel.stop
  end
    

  def process(request, response)
    response.start(201) do |head,out|
      if @response_delay
        puts "sleeping for #{@response_delay}"
        sleep(@response_delay)
      end
      body = request.body.read
      request.body.rewind
      if body =~ /name=\"type\"\r\n\r\ninfo\r\n/
        @info_payload_count += 1
      else
       @data_payload_count += 1
      end
      head["Content-Type"] = "application/json; charset=utf-8"
      out.write(response)
      puts "BOOM! #{@times_invoked} #{Time.now}"
    end
  end
   
  def response
   data = {"process_id"=>774736448, "metric_infos"=>[{"name"=>"rss", "id"=>932254199, "recipe_name"=>"ruby", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"pmem", "id"=>932254200, "recipe_name"=>"ruby", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"cpu", "id"=>932254201, "recipe_name"=>"ruby", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"activity", "id"=>932254194, "recipe_name"=>"activerecord", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"response_time", "id"=>932254195, "recipe_name"=>"actionpack", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"requests", "id"=>932254196, "recipe_name"=>"actionpack", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"render_time", "id"=>932254197, "recipe_name"=>"actionpack", "recipe_url"=>"http://dash.fiveruns.com"}, {"name"=>"queue_size", "id"=>932254198, "recipe_name"=>"rails", "recipe_url"=>"http://dash.fiveruns.com"}], "traces"=>[]}
   return data.to_json
  end

  def start
    if @startup_delay
      sleep(@startup_delay) 
      puts "starting up collector after a delay of #{@startup_delay}"
    end
    @mongrel = Mongrel::HttpServer.new("127.0.0.1", "9999")
    @mongrel.register("/", self)
    @mongrel.run
  end  
end
  


class CollectorCommunicationTest < Test::Unit::TestCase
  
  attr_reader :payload
  context "FiveRuns Dash Gem" do

    
    setup do
      no_recipe_loading!
      mock_configuration!
      create_session!
    #  mock_reporter!
      flexmock(@configuration).should_receive(:options).and_return(:app => '123')
      flexmock(::Fiveruns::Dash).should_receive(:configuration).and_return(@configuration)
      flexmock(@session.reporter).should_receive(:update_locations).returns(["http://localhost:9999"])
      flexmock(Fiveruns::Dash::Update).any_instance.should_receive(:check_response_of).returns(true)
      Thread.abort_on_exception = true
    end
    
    should "act properly" do
      # When the reporter starts, it immediately sends an info packet,
      # along with a regular payload
      collector = DummyCollector.new
      t = collector.start
      @session.reporter.interval = 5
      @session.reporter.start
      sleep(12) #enough for 2 cycles
      collector.stop
      assert_equal collector.info_payload_count, 1
      assert_equal collector.data_payload_count, 2
      #t.join
    end
    
    context "connection is refused" do
      should "continue to report if the first payload fails" do
        collector = DummyCollector.new(:startup_delay => 7)
        t = collector.start
        @session.reporter.interval = 5
        @session.reporter.start
        assert_equal collector.data_payload_count, 0
        sleep(12)
        assert_equal collector.info_payload_count, 1
        assert_equal collector.data_payload_count, 2
        collector.stop
        #t.join
      end
      
      should "continue to report if collector dies at a random time" do
        collector = DummyCollector.new()
        t = collector.start
        @session.reporter.interval = 5
        @session.reporter.start
        sleep(11)
        assert_equal collector.info_payload_count, 1
        assert_equal collector.data_payload_count, 2
        collector.stop      
        sleep(10)
        t = collector.start
        sleep(11)
        assert_equal collector.data_payload_count, 2
      end
    end
    
  end
  
  
  #######
  private
  #######
  
  def full_urls(service)
    full_uris(service).map(&:to_s)
  end
  
  def full_uris(service)
    @urls.map do |url|
      uri = URI.parse(url)
      uri.path = if service == :exceptions
        '/exceptions.json'
      else
        "/apps/123/#{service}.json"
      end
      uri
    end
  end

  def uris
    @urls.map { |url| URI.parse(url) }
  end
  
end
