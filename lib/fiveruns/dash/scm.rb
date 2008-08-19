require 'date'
module Fiveruns::Dash
  class SCM
    include Typable
    
    def self.matching(startpath)
      types.each do |name, klass|
        if path = locate_upwards(startpath, ".#{name}")
          Fiveruns::Dash.logger.info "SCM: Found #{name} in #{path}"
          return klass.new(path)
        end
      end
      nil
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
    
    def self.locate_upwards( startpath, target )
      startpath = File.expand_path(startpath)
      return startpath if File.exist?(File.join( startpath, target ))
      return locate_upwards( File.dirname(startpath), target) unless File.dirname(startpath) == startpath
      nil
    end

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

  class SvnSCM < SCM
    
    def revision
        @yaml['Last Changed Rev'] || @yaml['Revision']
    end
    
    def time
      DateTime.parse(@yaml['Last Changed Date'].split("(").first.strip)
    end
    
    def url
      @url ||= @yaml['URL']
    end
    
    #######
    private
    #######
    
    def require_binding
      @yaml = YAML.load(svn_info)
      @yaml = {} unless Hash === @yaml
    end

    def svn_info
      `svn info #{@path}`
    end
    
  end
  
end