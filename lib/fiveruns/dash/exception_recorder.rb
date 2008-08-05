require 'yaml'

module Fiveruns
  module Dash
  
  class ExceptionRecorder
    
    class << self
      def replacements
        @replacements ||= begin
          { 
            :system => /^(#{esc(path_prefixes(system_paths))})/,
            :gems   => /^(#{esc(path_prefixes(system_gempaths, '/gems'))})/
          }
        end
      end

      def system_gempaths
        `gem environment gempath`
      end
    
      def system_paths
        `ruby -e 'puts $:.reject{|p|p=="."}.join(":")'`
      end
    
      def path_prefixes( syspaths, suffix='')
        syspaths.strip.split(":").collect { |path| Pathname.new(path+suffix).cleanpath.to_s }
      end
    
      def esc( path_prefixes )
        path_prefixes.collect{|path|Regexp.escape(path)}.join('|')
      end
    end

    def initialize(session)
      @session = session
    end
    
    def record(exception, sample=nil)
      data = extract_data_from_exception(exception)
      if (matching = existing_exception_for(data))
        matching[:total] += 1
        matching
      else
        data[:total] = 1
        data[:serialized_sample] = serialize( sample ) unless sample.nil?
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

    def serialize( sample )
      YAML::dump(sample)
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
end