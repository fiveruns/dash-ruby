module Fiveruns::Dash
  
  class SCM
    include Typable
    
    def self.matching(path)
      types.each do |name, klass|
        if File.exists?(File.join(path, ".#{name}"))
          return klass.new(path)
        end
      end
    end
    
    def initialize(path)
      @path = path
      require_binding
    end
    
    def time
      raise NotImplementedError, 'Abstract'
    end
    
    def revision
      raise NotImplementedError, 'Abstract'
    end
    
    #######
    private
    #######

    def require_binding
    end
    
  end
  
  class GitSCM < SCM
    
    def revision
      commit.sha
    end
    
    def time
      commit.date
    end
    
    def url
      @url ||= begin
        origin = repo.remotes.detect { |r| r.name == 'origin' }
        origin.url if origin
      end
    end
    
    #######
    private
    #######
    
    def commit
      @commit ||= repo.object('HEAD')
    end
    
    def repo
      @repo ||= Git.open(@path)
    end

    def require_binding
      require 'git'
    rescue LoadError
      raise LoadError, "Requires the 'git' gem"
    end
    
  end
  
end