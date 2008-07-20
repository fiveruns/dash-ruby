require 'rubygems'
require 'activesupport'
require 'instrument'

require 'logger'

$:.unshift(File.dirname(__FILE__))
require 'dash/version'
require 'dash/configuration'
require 'dash/metric'
require 'dash/session'
require 'dash/reporter'
require 'dash/update'
require 'dash/host'

module Fiveruns
  
  module Dash
    
    def self.logger
      @logger ||= Logger.new($stdout)
    end
  
    def self.configure(options = {})
      configuration.options.update(options)
      yield configuration if block_given?
    end
    
    def self.start(options = {}, &block)
      configure(options, &block) if block_given?
      session.start
    end
    
    def self.host
      @host ||= Host.new
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