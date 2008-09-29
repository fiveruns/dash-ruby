module Fiveruns::Dash
  
  module Instrument
        
    class Error < ::NameError; end

    def self.handlers
      @handlers ||= []
    end
    
    # call-seq:
    #  Instrument.add("ClassName#instance_method", ...) { |instance, time, *args| ... }
    #  Instrument.add("ClassName::class_method", ...) { |klass, time, *args| ... }
    #  Instrument.add("ClassName.class_method", ...) { |klass, time, *args| ... }
    #
    # Add a handler to be called every time a method is invoked
    def self.add(*raw_targets, &handler)
      options = raw_targets.last.is_a?(Hash) ? raw_targets.pop : {}
      raw_targets.each do |raw_target|
        obj, meth = case raw_target
        when /^(.+)#(.+)$/
          [$1.constantize, $2]
        when /^(.+)(?:\.|::)(.+)$/
          [(class << $1.constantize; self; end), $2]
        else
          raise Error, "Bad target format: #{raw_target}"
        end
        instrument(obj, meth, options, &handler)
      end
    end  
    
    #######
    private
    #######

    def self.instrument(obj, meth, options = {}, &handler)
      handlers << handler unless handlers.include?(handler)
      offset = handlers.size - 1
      identifier = "instrument_#{handler.hash}"
      code = wrapping meth, identifier do |without|
        if options[:exceptions]
          <<-EXCEPTIONS
            begin
              #{without}(*args, &block)
            rescue Exception => _e
              _sample = ::Fiveruns::Dash::Instrument.handlers[#{offset}].call(self, *args)
              ::Fiveruns::Dash.session.add_exception(_e, _sample)
              raise
            end
          EXCEPTIONS
        else
          <<-PERFORMANCE
            # Invoke and time
            _start = Time.now          
            _result = #{without}(*args, &block)
            _time = Time.now - _start
            # Call handler (don't change *args!)
            ::Fiveruns::Dash::Instrument.handlers[#{offset}].call(self, _time, *args)
            # Return the original result
            _result
          PERFORMANCE
        end
      end
      obj.module_eval code
      identifier
    rescue SyntaxError => e
      puts "Syntax error (#{e.message})\n#{code}"
      raise
    rescue => e
      raise Error, "Could not attach (#{e.message})\n#{code}"
    end

    def self.wrapping(meth, feature)
      format = meth =~ /^(.*?)(\?|!|=)$/ ? "#{$1}_%s_#{feature}#{$2}" : "#{meth}_%s_#{feature}" 
      <<-DYNAMIC
        def #{format % :with}(*args, &block)
          _trace = Thread.current[:trace]
          if _trace
            _trace.step do
              #{yield(format % :without)}
            end
          else
            #{yield(format % :without)}
          end
        end
        alias_method_chain :#{meth}, :#{feature}
      DYNAMIC
    end
      
  end
  
end