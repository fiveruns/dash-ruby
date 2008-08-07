require 'rubygems'
require 'activesupport'

require 'logger'

$:.unshift(File.dirname(__FILE__))
require 'dash/version'
require 'dash/configuration'
require 'dash/metric'
require 'dash/session'
require 'dash/reporter'
require 'dash/update'
require 'dash/host'
require 'dash/scm'
require 'dash/exception_recorder'
require 'dash/recipe'
require 'dash/instrument'

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
    
    def self.scm
      @scm ||= unless configuration.options[:scm] == false
        SCM.matching(configuration.options[:scm_repo])
      end
    end
        
    class << self
      attr_accessor :process_id
    end
    
    def self.register_recipe(name, options = {}, &block)
      recipes[name] ||= []
      recipes[name] << Recipe.new(name, options, &block)
    end

    def self.recipes
      @recipes ||= {}
    end
        
    #######
    private
    #######
        
    def self.session
      @session ||= Session.new(configuration)
    end
    
    def self.configuration
      @configuration ||= begin
        load_recipes
        Configuration.new
      end
    end
    
    def self.load_recipes
      @recipe_loader ||= returning Recipe::Loader.new do |loader|
        loader.run
      end
    end
    
  end
  
end