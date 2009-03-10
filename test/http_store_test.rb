require File.dirname(__FILE__) << "/test_helper"

class HTTPStoreTest < Test::Unit::TestCase
  
  attr_reader :payload

  context "HTTPStore" do
    
    setup do
      mock!
      Thread.current[:resolved_hostnames] = nil
      @urls = %w(http://metrics.foo.com http://metrics02.bar.com http://metrics03.bar.com)
      @klass = Class.new { include Write::Store::HTTP }
      @params = {:this_is_a_param => 'value'}
      @metric = flexmock(:metric) do |mock|
        mock.should_receive(:key).and_return(:name => 'MetricTest.time_me', :recipe_name => nil, :recipe_url => nil)
        mock.should_receive(:info_id=)
      end
      flexmock(Fiveruns::Dash.application.configuration) do |mock|
        mock.should_receive(:options).and_return(:token => '123')
        mock.should_receive(:metrics).and_return([@metric])
      end
      flexmock(@klass).new_instances do |mock|
        mock.should_receive(:payload).and_return { payload }
        mock.should_receive(:params).and_return(@params)
      end
      @update = @klass.new
   #   mock_streams!
    end
    
    teardown do
      FakeWeb.clean_registry
   #   restore_streams!
    end
    
    #TODO
    context "collector hostnames" do
      should "should be resolved on the first access" do 
        flexmock(IPSocket).should_receive(:getaddress).times(1).returns("1.1.1.1")
        assert_equal @update.resolved_hostnames.keys.size, 0
        new_uri = @update.resolved_hostname(uris.first.host)        
        assert_equal new_uri, "1.1.1.1"
        assert_equal @update.resolved_hostnames.keys.size, 1
        assert @update.resolved_hostnames[uris.first.host].next_update > (Time.now + (23 * 60 * 60))
        assert_equal @update.resolved_hostname(uris.first.host), "1.1.1.1"
        junk = @update.resolved_hostname(uris.first.host)        
        
      end
      
      should "re-cache address if time has expired" do
        flexmock(@update).should_receive(:rand).returns(1)
        flexmock(IPSocket).should_receive(:getaddress).returns("1.1.1.1", "2.2.2.2")
        assert_equal @update.resolved_hostnames.keys.size, 0
        new_uri = @update.resolved_hostname(uris.first.host)   
        assert_equal new_uri, "1.1.1.1"
        @update.resolved_hostnames[uris.first.host].next_update = Time.now - (10 * 60 * 60)
        first_expire = @update.resolved_hostnames[uris.first.host].next_update
        
        new_uri = @update.resolved_hostname(uris.first.host)   
        second_expire = @update.resolved_hostnames[uris.first.host].next_update
        assert_equal new_uri, "2.2.2.2"
        assert second_expire < (Time.now + (25 * 60 * 60))
        assert second_expire > (Time.now + (23 * 60 * 60))
      end
    end
    
    context "with info payload" do
      setup do
        @payload = Write::InfoPayload.new({:pid => 987}, Time.now.utc)
        @update#TODO
        flexmock(@update).should_receive(:resolved_hostname).and_return {|c| c }
   #     restore_streams!
      end
      teardown do
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
          pass_uri = @update.store_http(*uris)
          assert_equal uris[1], pass_uri
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
        end
      end
    end
    
    context "with data payload" do

      setup do
        @payload = Write::DataPayload.new([{:metric_info_id => 123, :name => 'bar'}])
        flexmock(@update).should_receive(:resolved_hostname).and_return {|c| c}
        
      end
    
      context "fallback URLs" do
        context "on connection error" do
          setup do
            FakeWeb.register_uri full_urls(:metrics).first, :string => 'FAIL!', :exception => Net::HTTPError
            full_urls(:metrics)[1..-1].each do |url|
              FakeWeb.register_uri url, :string => '{"message" : "OK!"}', :status => 201
            end
          end
          should "fallback to working URL" do
            pass_uri = @update.store_http(*uris)
            assert_equal uris[1], pass_uri
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
        @payload = Write::ExceptionsPayload.new([
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
        flexmock(@update).should_receive(:resolved_hostname).and_return {|c| c}
        
      end
    
      context "fallback URLs" do
        context "on connection error" do
          setup do
            FakeWeb.register_uri full_urls(:exceptions).first, :string => 'FAIL!', :exception => Net::HTTPError
            full_urls(:exceptions)[1..-1].each do |url|
              FakeWeb.register_uri url, :string => '{"message" : "OK!"}', :status => 201
            end
          end
          should "fallback to working URL" do
            pass_uri = @update.store_http(*uris)
            assert_equal uris[1], pass_uri
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
    full_uris(service).map { |u| u.to_s }
  end
  
  def full_uris(service)
    @urls.map do |url|
      uri = URI.parse(url)
      uri.path = "/apps/123/#{service}.json"
      uri
    end
  end

  def uris
    @urls.map { |url| URI.parse(url) }
  end

end