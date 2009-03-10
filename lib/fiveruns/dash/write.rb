module Fiveruns::Dash::Write
  
  module Helpers
        
    # =============
    # = THREADING =
    # =============
    
    def monitor
      @monitor ||= Monitor.new
    end
    
    def sync(&block)
      monitor.synchronize(&block)
    end
    
    # =========================
    # = CONFIGURATION/STARTUP =
    # =========================

    def configure(options = {})
      handle_pwd_is_root(caller[0]) if Dir.pwd == '/'      
      configuration.options.update(options)
      yield configuration if block_given?
    end

    def start(options = {}, &block)
      configure(options, &block) if block_given?
      session.start
    end
    
    # ===========
    # = RECIPES =
    # ===========

    def register_recipe(name, options = {}, &block)
      recipes[name] ||= []
      recipe = Fiveruns::Dash::Write::Recipe.new(name, options, &block)
      if recipes[name].include?(recipe)
        logger.info "Skipping re-registration of recipe :#{name} #{options.inspect}"
      else
        recipes[name] << recipe
      end
    end

    def recipes
      @recipes ||= {}
    end
    
    # ========
    # = MISC =
    # ========

    def scm
      @scm ||= unless configuration.options[:scm] == false
        Fiveruns::Dash::Write::SCM.matching(configuration.options[:scm_repo])
      end
    end
    
    def configuration
      @configuration ||= begin
        load_recipes
        Fiveruns::Dash::Write::Configuration.new
      end
    end
    
    def session
      @session ||= Fiveruns::Dash::Write::Session.new(configuration)
    end

    #######
    private
    #######

    def handle_pwd_is_root(last_method)
      # We are in a Daemon and don't have a valid PWD.  Change the
      # default SCM repo location based on the caller stack.
      if last_method =~ /([^:]+):\d+/
        file = File.dirname($1)
        configuration.options[:scm_repo] = file
      end
    end

    def load_recipes
      Dir[File.join(File.dirname(__FILE__), '..', '..', 'recipes', '**', '*.rb')].each do |core_recipe|
        require core_recipe
      end
    end
    
  end
  
end
    