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
        load_core_recipes
        load_gem_recipes
        Configuration.new
      end
    end
    
    
    def self.load_core_recipes
      @loaded_core_recipes ||= begin
        logger.warn "Registering core recipes"
        journal_recipes do
          Dir[File.dirname(__FILE__) << "/../../recipes/*.rb"].each do |file|
            require file
          end
        end
        true
      end
    end
    
    def self.load_gem_recipes
      @loaded_gem_recipes ||= begin
        logger.info "Registering gem recipes..."
        spec_path = File.join(Gem.dir, 'specifications')
        gems = Gem::SourceIndex.from_installed_gems(spec_path)
        gems.each do |path, gem|
          gem.dependencies.each do |dependency|
            if dependency.name == 'fiveruns_dash'
              gem_path = File.join(Gem.dir, "gems", path)
              logger.info "Registering recipes from #{path}"
              journal_recipes do
                Dir[File.join(gem_path, 'dash/**/*.rb')].each do |file|                
                  require file
                end
              end
            end
          end
        end
        true
      end
    end
    
    def self.journal_recipes
      list = recipes.values.flatten.dup
      yield
      delta = recipes.values.flatten - list
      delta.each do |recipe|
        logger.info "> Registered `#{recipe.name}' (#{recipe.url})"
      end
    end
    
  end
  
end