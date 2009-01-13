require File.dirname(__FILE__) << "/test_helper"

class ExceptionRecorderTest < Test::Unit::TestCase
  
  attr_reader :payload
  attr_reader :recorder, :exceptions

  context "ExceptionRecorder" do
    
    setup do
      @recorder = Fiveruns::Dash::ExceptionRecorder.new(flexmock(:session))
      flexmock(ExceptionRecorder).should_receive(:replacements).and_return({
        :foo => /^foo\b/
      })
    end
    
    context "when recording an exception" do
      setup do
        recorder.record(build("Message", "foo/bar/baz"))
      end
      should "record an exception" do
        assert_equal 1, recorder.data.size
      end
      should "normalize a backtrace" do
        assert(recorder.data.first[:backtrace] =~ /\[FOO\]/)
      end
    end

    context "when recording an exception with a sample" do
      setup do
        recorder.record(build("Message", "foo/bar/baz"), {:key => :value})
      end
      should "record an exception" do
        assert_equal 1, recorder.data.size
      end
      should "normalize a backtrace" do
        assert(recorder.data.first[:backtrace] =~ /\[FOO\]/)
      end      
      should "not serialize sample" do
        assert_equal({'key' => 'value'}, recorder.data.first[:sample])
      end      
    end
    
    context "when recording exceptions with the same message and backtrace" do
      setup do
        recorder.record(build, :key1=>:value1)
        recorder.record(build, :key2=>:value2)
      end
      should "collapse" do
        assert_equal 1, recorder.data.size
      end
      should "count them together" do
        assert_equal [2], recorder.data.map { |exc| exc[:total] }
      end
      should "store only the first sample" do
        assert_equal({'key1' => 'value1'}, recorder.data.first[:sample])
      end
    end
    
    context "when recording exceptions with different messages" do
      setup do
        recorder.record(build("Message1", "Line 1"))
        recorder.record(build("Message2", "Line 1"))
      end
      should "collapse" do
        assert_equal 1, recorder.data.size
      end
      should "count them together" do
        assert_equal [2], recorder.data.map { |exc| exc[:total] }
      end
    end
    
    context "when recording exceptions with different backtraces" do
      setup do
        recorder.record(build("Message", "Line 1"))
        recorder.record(build("Message", "Line 2"))
      end
      should "not collapse" do
        assert_equal 2, recorder.data.size
      end
      should "count them separately" do
        assert_equal [1, 1], recorder.data.map { |exc| exc[:total] }
      end
    end

    context "when retrieving the data" do
      should "call reset when returning data hash" do
        flexmock(recorder).should_receive(:reset).once
        recorder.data
      end
    
      should "empty the exception list on reset" do
        recorder.send(:exceptions) << "Item"
        assert_equal( 1, recorder.send(:exceptions).size )
        recorder.send(:reset)
        assert_equal( 0, recorder.send(:exceptions).size )
      end
    end

  end
  
  #######
  private
  #######

  def build(message = 'This is a message', line = 'backtrace line')
    flexmock(:exception) do |mock|
      mock.should_receive(:backtrace).and_return([line])        
      mock.should_receive(:message).and_return(message)
    end
  end
end