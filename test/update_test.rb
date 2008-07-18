require File.dirname(__FILE__) << "/test_helper"

class UpdateTest < Test::Unit::TestCase

  context "Update" do

    setup do
      @update = Update.new(:test, {}, nil)
    end
    
    context "an instance" do
    
      context "GUID" do
        setup do
          @mock_pid = 'THE-PID'
          flexmock(Process).should_receive(:pid).and_return(@mock_pid)
        end
        should "include PID" do
          @update.guid.include?(@mock_pid)
        end
        should "start with a a timestamp" do
          @update.guid[/^\d{10,}/]
        end
        should "be cached per instance" do
          assert_equal @update.guid, @update.guid
        end
      end
      
      context "storing data" do
        setup do
          @urls = %w(file:///tmp http://yahoo.com https://secure.thing.com)
        end
        should "find correct method" do
          assert_equal [:file, :http, :http], @urls.map { |url| @update.send(:storage_method_for, URI.parse(url).scheme) }
        end
      end
      
    end

  end

end