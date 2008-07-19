require File.dirname(__FILE__) << "/test_helper"

class HTTPStoreTest < Test::Unit::TestCase

  context "HTTPStore" do

    setup do
      @urls = %w(http://metrics.foo.com http://metrics02.bar.com http://metrics03.bar.com)
      @klass = Class.new { include Store::HTTP }
      @payload = Payload.new(:test, {:foo => 'bar'})
      @params = {:this_is_a_param => 'value'}
      @configuration = flexmock(:config) do |mock|
        mock.should_receive(:options).and_return(:app => '123')
      end
      flexmock(@klass).new_instances do |mock|
        mock.should_receive(:configuration).and_return(@configuration)
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
          FakeWeb.register_uri full_urls.first, :string => 'FAIL!', :exception => Net::HTTPError
          full_urls[1..-1].each do |url|
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
          [500, 403, 200].zip(full_urls).each do |status, url|
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
  
  def full_urls
    full_uris.map(&:to_s)
  end
  
  def full_uris
    @urls.map do |url|
      uri = URI.parse(url)
      uri.path = "/apps/123/metrics.yml"
      uri
    end
  end

  def uris
    @urls.map { |url| URI.parse(url) }
  end

end