require 'rubygems'
require 'activesupport'
require 'instrument'

$:.unshift(File.dirname(__FILE__))
require 'dash/version'
require 'dash/configuration'
require 'dash/metric'
require 'dash/session'

module Fiveruns
  
  module Dash
  
    def self.configure(options = {})
      yield configuration
    end
    
    def self.start
      session.start
    end
    
    #######
    private
    #######    
    
    def self.session
      @session ||= Session.new(configuration)
    end
    
    def self.configuration
      @configuration ||= Configuration.new
    end
    
  end
  
end