require 'yaml'

module Fiveruns
  module Dash
  
  class ExceptionRecorder

    RULES = []
    
    class << self
      def replacements
        @replacements ||= begin
          paths = {
            :system => /^(#{esc(path_prefixes(system_paths))})/,
            :gems   => /^(#{esc(path_prefixes(system_gempaths, '/gems'))})/
          }
          %w(RAILS_ROOT MERB_ROOT).each do |root|
            const = nil
            const = Object.const_get(root) if Object.const_defined?(root)
            paths.merge({ :app => regexp_for_path(const) }) if const
          end
          paths
        end
      end

      def system_gempaths
        `gem environment gempath`
      end
    
      def system_paths
        `ruby -e 'puts $:.reject{|p|p=="."}.join(":")'`
      end

      def regexp_for_path(path)
        /^(#{Regexp.escape(Pathname.new(path).cleanpath.to_s)})/
      end
    
      def path_prefixes(syspaths, suffix='')
        syspaths.strip.split(":").collect { |path| Pathname.new(path+suffix).cleanpath.to_s }
      end
    
      def esc(path_prefixes)
        path_prefixes.collect{|path|Regexp.escape(path)}.join('|')
      end

      def add_ignore_rule(&rule)
        RULES << rule
      end
    end

    def initialize(session)
      @session = session
    end
    
    def exception_annotations
      @exception_annotaters ||= []
    end
    
    def ignore_exception?(exception)
      RULES.any? do |rule|
        rule.call(exception)
      end
    end
    
    def record(exception, sample=nil)
      return if ignore_exception? exception
      
      run_annotations(sample)
      
      data = extract_data_from_exception(exception)
      # Allow the sample data to override the exception's display name.
      data[:name] = sample.delete(:name) if sample and sample[:name]

      if (matching = existing_exception_for(data))
        matching[:total] += 1
        matching
      else
        data[:total] = 1
        data[:sample] = flatten_sample sample
        exceptions << data
        data
      end
    end
    
    def data
      duped = exceptions.dup
      reset
      duped
    end

    def reset
      exceptions.clear
    end
    
    def add_annotation(&annotation)
      exception_annotations << annotation
    end
    
    #######
    private
    #######
    
    def run_annotations(sample)
      exception_annotations.each do |annotation|
        annotation.call(sample)
      end
      
      return sample
    end
    
    def flatten_sample(sample)
      case sample
      when Hash
        Hash[*sample.to_a.flatten.map { |v| v.to_s }]
      when nil
        {}
      else
        raise ArgumentError, "Exception sample must be a Hash instance"
      end
    end

    def existing_exception_for(data)
      # We detect exception dupes based on the same class name and backtrace.
      exceptions.detect { |e| data[:name] == e[:name] && data[:backtrace] == e[:backtrace] }
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