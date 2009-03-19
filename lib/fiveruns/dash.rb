require 'rubygems'

module Fiveruns; end

# Attempt to load the 'json' gem first
# We do this because, under some curcumstances,
# the json/ext complains if loaded after our forked
# copy.
begin
  require 'json'
rescue  
  # Skip
end

# Pull in our forked copy of the pure JSON gem
require 'fiveruns/json'

require 'pathname'
require 'thread'
require 'time'
require 'logger'

$:.unshift(File.dirname(__FILE__))

# NB: Pre-load ALL Dash files here so we do not accidentally
# use ActiveSupport's autoloading.
require 'dash/version'
require 'dash/util'
require 'dash/configuration'
require 'dash/typable'
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
require 'dash/store/http'
require 'dash/store/file'

module Fiveruns::Dash
    
  include Threads
  
  START_TIME = Time.now.utc
  
  def self.process_age
    Time.now.utc - START_TIME
  end
          
  def self.logger
    @logger ||= begin
      if defined?(RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      else
        Logger.new(STDOUT)
      end
    end
  end
  
  def self.logger=(logger)
    @logger = logger
  end

  def self.configure(options = {})
    handle_pwd_is_root(caller[0]) if Dir.pwd == '/'      
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
    attr_accessor :trace_contexts
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
    Dir[File.join(File.dirname(__FILE__), '..', '..', 'recipes', '**', '*.rb')].each do |core_recipe|
      require core_recipe
    end
  end
  
  module Context
    def self.set(value)
      Thread.current[:fiveruns_dash_context] = value
    end
  
    def self.reset
      Thread.current[:fiveruns_dash_context] = []
    end
  
    def self.context
      Thread.current[:fiveruns_dash_context] ||= []
    end
  end

end
