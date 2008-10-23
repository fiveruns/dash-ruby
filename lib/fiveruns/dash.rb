require 'rubygems'
require 'activesupport'
require 'json'

require 'thread'

# Replace Ruby's default native Resolv with the pure ruby Resolv
# so DNS lookups do not block the entire process.
# resolv-replace does not work for localhost on most Macs. Use 
# 127.0.0.1 instead
require 'resolv-replace'

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
require 'dash/threads'
require 'dash/trace'

module Fiveruns
  
  module Dash
    
    include Threads
    
    START_TIME = Time.now.utc
    
    def self.process_age
      Time.now.utc - START_TIME
    end
            
    def self.logger
      @logger ||= Logger.new($stdout)
    end
    
    def self.logger=(logger)
      @logger = logger
    end
  
    def self.configure(options = {})
      configuration.options.update(options)
      yield configuration if block_given?
    end
    
    def self.start(options = {}, &block)
      handle_pwd_is_root(caller[0]) if Dir.pwd == '/'
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

    # Support for multiple fake hosts in development
    def self.process_id=(value)
      @process_ids ||= []
      if value
        @process_ids << value
      else
        @process_ids.clear
      end
    end

    def self.process_id
      @process_ids ||= []
      @process_ids[0]
    end
        
    class << self
      attr_accessor :process_ids, :trace_contexts
    end
    
    def self.register_recipe(name, options = {}, &block)
      recipes[name] ||= []
      recipe = Recipe.new(name, options, &block)
      if recipes[name].include?(recipe)
        logger.info "Skipping re-registration of recipe :#{name} #{options.inspect}"
      else
        recipes[name] << recipe
      end
    end

    def self.recipes
      @recipes ||= {}
    end
    
    def self.trace_contexts
      @trace_contexts ||= []
    end
        
    #######
    private
    #######
        
    def self.handle_pwd_is_root(last_method)
      # We are in a Daemon and don't have a valid PWD.  Change the
      # default SCM repo location based on the caller stack.
      if last_method =~ /([^:]+):\d+/
        file = File.dirname($1)
        configuration.options[:scm_repo] = file
      end
    end

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
