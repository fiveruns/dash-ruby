module Fiveruns::Dash::Write
  
  module Helpers
    
    def self.included(base)
      base.extend ClassMethods
    end
      
    module ClassMethods
        
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

      def configure(options = {}, &block)
        self.application ||= Fiveruns::Dash::Application.new(:write)
        if Dir.pwd == '/'
          guessed_pwd = guess_pwd(caller[0])
          options[:scm_repo] ||= guessed_pwd if guessed_pwd
        end
        application.configure(options, &block)
      end

      def start(options = {}, &block)
        configure(options, &block)
        application.validate!
        application.session.start
      end
        
      # ===========
      # = RECIPES =
      # ===========
    
      def register_recipe(*args, &block)
        Fiveruns::Dash.logger.debug "DEPRECATED Fiveruns::Dash.register_recipe. Use Fiveruns::Dash.recipe"
        recipe(*args, &block)
      end

      def recipe(name, options = {}, &block)
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

      #######
      private
      #######

      def guess_pwd(last_method)
        # We are in a Daemon and don't have a valid PWD.  Change the
        # default SCM repo location based on the caller stack.
        if last_method =~ /([^:]+):\d+/
          File.dirname($1)
        end
      end
      
    end
    
  end
  
end
    