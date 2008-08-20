require File.dirname(__FILE__) << "/test_helper"

class FileStoreTest < Test::Unit::TestCase

  context "FileStore" do

    setup do
      mock_storage!
      directories.each do |dir|
        FileUtils.mkdir_p dir
      end
      @update = @klass.new
      @update.store_file(*uris)
    end

    teardown do
      FileUtils.rm_rf(File.dirname(__FILE__) << "/tmp")
    end
    
    should "write to all filenames" do
      assert_equal 2, files.size
    end
    
    should "name all filenames the same" do
      assert_equal 1, files.map { |f| File.basename(f) }.uniq.size
    end

  end
  
  #######
  private
  #######
  
  def files
    Dir[File.dirname(__FILE__) << "/tmp/**/*.json"]
  end
  
  def mock_storage!
    @klass = Class.new { include Store::File }
    flexmock(@klass).new_instances do |mock|
      mock.should_receive(:payload).and_return(:foo => 1, :bar => 2)
      mock.should_receive(:guid).and_return('GUID')
    end
  end
  
  def directories
    %w(foo bar).map do |name|
      File.expand_path(File.join(File.dirname(__FILE__), 'tmp', 'file_store', name))
    end  
  end
  
  def uris
    directories.map { |path| URI.parse("file://#{path}") }
  end

end