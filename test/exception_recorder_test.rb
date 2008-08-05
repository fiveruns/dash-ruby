require File.dirname(__FILE__) << "/test_helper"

class ExceptionRecorderTest < Test::Unit::TestCase
  
  attr_reader :payload

  context "ExceptionRecorder" do
    setup do
      mock!
      @recorder = ExceptionRecorder.new( @session )
      @fakesystempaths = "/Library/Ruby/1.8:/Library/Ruby/1.8/powerpc-darwin9.0"
      @fakegempaths = "/Library/Ruby/Gems/1.8:/usr/local/gems"
    end
    
    should "extract exception data" do
      begin
        raise ArgumentError.new("I am an exception")
      rescue => e
        flexmock(@recorder).should_receive(:sanitize).and_return "sanitized_backtrace"
        data = @recorder.send(:extract_data_from_exception, e)  
        assert_equal( "ArgumentError", data[:name])
        assert_equal( "I am an exception", data[:message])
        assert_equal( "sanitized_backtrace", data[:backtrace])
      end
    end
    
    should "santize_backtrace_using_replacements" do
    end
    
    should "convert sample to yaml on serialize" do
      assert_equal( YAML::dump( :key => :value ),  @recorder.send(:serialize, {:key => :value}))
    end
    
    should "record first exception successfully with sample" do
    end
    
    should "incrememnt count for subsequent identical exceptions, and ignore sample" do
    end
    
    should "find_existing_exception for matching key/bvalues" do
    end

    should "not find_existing_exception for differing key/bvalues" do
    end
    
    should "call reset when returning data hash" do
    end
    
    should "empty the exception list on reset" do
      @recorder.send(:exceptions) << "Item"
      assert_equal( 1, @recorder.send(:exceptions).size )
      @recorder.send(:reset)
      assert_equal( 0, @recorder.send(:exceptions).size )
    end
    
    should "provide correct replacements" do
      flexmock(ExceptionRecorder).should_receive(:system_paths).once.and_return(@fakesystempaths)
      flexmock(ExceptionRecorder).should_receive(:path_prefixes).once.with(@fakesystempaths).and_return "syspath"
      flexmock(ExceptionRecorder).should_receive(:esc).once.with("syspath").and_return "escaped_syspath" 
      flexmock(ExceptionRecorder).should_receive(:system_gempaths).once.and_return(@fakegempaths)
      flexmock(ExceptionRecorder).should_receive(:path_prefixes).once.with(@fakegempaths, "/gems").and_return "gempath"
      flexmock(ExceptionRecorder).should_receive(:esc).once.with("gempath").and_return "escaped_gempath" 
      
      reps = ExceptionRecorder.replacements
      expected_replacements = { :system=> /^(escaped_syspath)/, :gems=> /^(escaped_gempath)/ }
      assert_equal expected_replacements.size, reps.size
      assert_equal expected_replacements[:system].to_s, reps[:system].to_s 
      assert_equal expected_replacements[:gems].to_s, reps[:gems].to_s 
    end
  end
end