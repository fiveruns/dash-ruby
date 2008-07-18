require File.dirname(__FILE__) << "/test_helper"

class HTTPStoreTest < Test::Unit::TestCase

  context "HTTPStore" do

    setup do
      @urls = %w(http://metrics.foo.com/metrics.yml http://metrics02.bar.com/metrics.yml http://metrics03.bar.com/metrics.yml)
      @klass = Class.new { include Store::HTTP }
      @payload = Payload.new({:foo => 'bar'})
      @params = {:this_is_a_param => 'value'}
      flexmock(@klass).new_instances do |mock|
        mock.should_receive(:payload).and_return(@payload)
        mock.should_receive(:params).and_return(@params)
      end
      @update = @klass.new
      mock_streams!
    end
    
    teardown do
      FakeWeb.clean_registry
      restore_streams!
    end
    
    context "fallback URLs" do
      context "on connection error" do
        setup do
          FakeWeb.register_uri @urls.first, :string => 'FAIL!', :exception => Net::HTTPError
          @urls[1..-1].each do |url|
            FakeWeb.register_uri url, :string => 'OK!', :status => 201
          end
        end
        should "fallback to working URL" do
          assert_equal uris[1], @update.store_http(*uris)
        end
      end
      context "on non-201 response" do
        setup do
          [500, 403, 200].zip(@urls).each do |status, url|
            FakeWeb.register_uri url, :string => 'Not what we want', :status => status
          end
        end
        should "not succeed" do
          assert !@update.store_http(*uris)
        end
      end
    end

  end
  
  #######
  private
  #######

  def uris
    @urls.map { |url| URI.parse(url) }
  end

end