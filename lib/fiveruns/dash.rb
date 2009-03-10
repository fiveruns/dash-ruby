require 'rubygems'

module Fiveruns
  module Dash
  end  
end

# Pull in our forked copy of the pure JSON gem
require 'fiveruns/json'

require 'date'
require 'pathname'
require 'thread'
require 'time'
require 'logger'
require 'zlib'
require 'yaml'

# NB: Pre-load ALL Dash files here so we do not accidentally
# use ActiveSupport's autoloading.
$:.unshift(File.dirname(__FILE__))
require 'dash/version'
require 'dash/util'
require 'dash/host'
require 'dash/logging'
require 'dash/application'
require 'dash/typable'
require 'dash/write'
require 'dash/read'

%w(read write).each do |mode|
  Dir[File.join(File.dirname(__FILE__), 'dash', mode, '**', '*.rb')].each do |file|
    require file
  end
end

module Fiveruns::Dash
  extend Logging
  
  # Add some class methods
  extend Write::Helpers
  extend Read::Helpers
    
  def self.host
    @host ||= Host.new
  end
  
  START_TIME = Time.now.utc
  def process_age
    Time.now.utc - START_TIME
  end

end