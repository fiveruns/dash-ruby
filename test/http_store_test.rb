require File.dirname(__FILE__) << "/test_helper"

class HTTPStoreTest < Test::Unit::TestCase
  
  attr_reader :payload

  context "HTTPStore" do
    
    setup do
      @urls = %w(http://metrics.foo.com http://metrics02.bar.com http://metrics03.bar.com)
      @klass = Class.new { include Store::HTTP }
      @params = {:this_is_a_param => 'value'}
      @metric = flexmock(:metric) do |mock|
        mock.should_receive(:key).and_return(:name => 'MetricTest.time_me', :recipe_name => nil, :recipe_url => nil)
        mock.should_receive(:info_id=)
      end
      @configuration = flexmock(:config) do |mock|
        mock.should_receive(:options).and_return(:app => '123')
        mock.should_receive(:metrics).and_return([@metric])
      end
      flexmock(@klass).new_instances do |mock|
        mock.should_receive(:configuration).and_return(@configuration)
        mock.should_receive(:payload).and_return { payload }
        mock.should_receive(:params).and_return(@params)
      end
      @update = @klass.new
      no_recipe_loading!
   #   mock_streams!
    end
    
    teardown do
      FakeWeb.clean_registry
   #   restore_streams!
    end
    
    context "with info payload" do
      setup do
        @payload = InfoPayload.new({:pid => 987}, Time.now.utc)
   #     restore_streams!
      end
      teardown do
        Fiveruns::Dash.process_id = nil
   #     mock_streams!
      end
      context "on connection error" do
        setup do
          FakeWeb.register_uri full_urls(:processes).first, :string => 'FAIL!', :exception => Net::HTTPError
          full_urls(:processes)[1..-1].each do |url|
            FakeWeb.register_uri url, :status => 201, :string => File.read(File.dirname(__FILE__) << "/fixtures/http_store_test/response.json")
          end
        end
        should "fallback to working URL" do
          returning @update.store_http(*uris) do |pass_uri|
            assert_equal uris[1], pass_uri
          end
          assert_equal 1, Fiveruns::Dash.process_id
        end
      end
      context "on non-201 response" do
        setup do
          [500, 403, 200].zip(full_urls(:processes)).each do |status, url|
            FakeWeb.register_uri url, :string => 'Not what we want', :status => status
          end
        end
        should "not succeed" do
          assert !@update.store_http(*uris)
          assert_nil Fiveruns::Dash.process_id
        end
      end
    end
    
    context "with data payload" do

      setup do
        @payload = DataPayload.new([{:metric_info_id => 123, :name => 'bar'}])
      end
    
      context "fallback URLs" do
        context "on connection error" do
          setup do
            FakeWeb.register_uri full_urls(:metrics).first, :string => 'FAIL!', :exception => Net::HTTPError
            full_urls(:metrics)[1..-1].each do |url|
              FakeWeb.register_uri url, :string => 'OK!', :status => 201
            end
          end
          should "fallback to working URL" do
            returning @update.store_http(*uris) do |pass_uri|
              assert_equal uris[1], pass_uri
            end
          end
        end
        context "on non-201 response" do
          setup do
            [500, 403, 200].zip(full_urls(:metrics)).each do |status, url|
              FakeWeb.register_uri url, :string => 'Not what we want', :status => status
            end
          end
          should "not succeed" do
            assert !@update.store_http(*uris)
          end
        end
      end

    end
    
    context "with exceptions payload" do

      setup do
        @payload = ExceptionsPayload.new([
          {
            :name => 'FooError',
            :message => 'Fake Foo Error',
            :backtrace => '--- This is not real',
            :total => 3
          },
          {
            :name => 'BarError',
            :message => 'Fake Bar Error',
            :backtrace => '--- This is not real',
            :total => 10
          }
        ])
      end
    
      context "fallback URLs" do
        context "on connection error" do
          setup do
            FakeWeb.register_uri full_urls(:exceptions).first, :string => 'FAIL!', :exception => Net::HTTPError
            full_urls(:exceptions)[1..-1].each do |url|
              FakeWeb.register_uri url, :string => 'OK!', :status => 201
            end
          end
          should "fallback to working URL" do
            returning @update.store_http(*uris) do |pass_uri|
              assert_equal uris[1], pass_uri
            end
          end
        end
        context "on non-201 response" do
          setup do
            [500, 403, 200].zip(full_urls(:exceptions)).each do |status, url|
              FakeWeb.register_uri url, :string => 'Not what we want', :status => status
            end
          end
          should "not succeed" do
            assert !@update.store_http(*uris)
          end
        end
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