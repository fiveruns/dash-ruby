module Fiveruns::Dash
  
  class ExceptionRecorder
    
    def self.replacements
      @replacements ||= begin
        paths = `gem environment gempath`.strip.split(":")
        gems_path_prefixes = paths.collect { |path| Pathname.new(path+"/gems").cleanpath.to_s }

        paths = `ruby -e 'puts $:.reject{|p|p=="."}.join(":")'`.strip.split(":")
        system_path_prefixes = paths.collect { |path| Pathname.new(path).cleanpath.to_s }
        { 
          :gems   => /^(#{gems_path_prefixes.collect{|path|Regexp.escape(path)}.join('|')})/,
          :system => /^(#{system_path_prefixes.collect{|path|Regexp.escape(path)}.join('|')})/
        }
      end
    end
    
    def initialize(session)
      @session = session
    end
    
    def record(exception)
      data = extract_data_from_exception(exception)
      if (matching = existing_exception_for(data))
        matching[:total] += 1
        matching
      else
        data[:total] = 1
        exceptions << data
        data
      end
    end
    
    def data
      returning exceptions.dup do
        reset
      end
    end
    
    #######
    private
    #######
    
    def existing_exception_for(data)
      exceptions.detect { |e| data.all? { |k,v| e[k] == v } }
    end
    
    def extract_data_from_exception(e)
      {
        :name => e.class.name,
        :message => e.message,
        :backtrace => sanitize(e.backtrace)
      }
    end

    def exceptions
      @exceptions ||= []
    end
    
    def reset
      exceptions.clear
    end
    
    def sanitize(backtrace)
      backtrace.map do |line|
        line = line.strip
        line.gsub!('in `', "")
        line.gsub!("'", "")
        self.class.replacements.each do |name, pattern|
          line.gsub!(pattern,  "[#{name.to_s.upcase}]")
        end
        Pathname.new(line).cleanpath.to_s
      end.join("\n")
    end
    
  end
  
end