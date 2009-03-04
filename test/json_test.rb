require File.dirname(__FILE__) << "/test_helper"
require 'zlib'

class JsonTest < Test::Unit::TestCase

  def profile(name, &block)
    require 'ruby-prof'
    result = RubyProf.profile(&block)
    printer = RubyProf::GraphHtmlPrinter.new(result)
    File.open("#{name}.html", 'w') do |f|
      printer.print(f, :min_percent=>1)
    end
  end
  
  def xprofile(name, &block)
    block.call
  end
  
  def setup
    File.open("#{File.dirname(__FILE__)}/data_payload.bin.gz") do |f|
      @data = eval(Zlib::GzipReader.new(f).read)
    end
  end

	def test_serialization
		xprofile('fjson') do
			@data.to_fjson
		end
		a = Time.now
		fjson = @data.to_fjson
#		puts "FJSON: #{Time.now - a}"
	end
end
