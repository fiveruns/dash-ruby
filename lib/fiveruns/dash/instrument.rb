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
      raw_targets.each do |raw_target|
        obj, meth = case raw_target
        when /^(.+)#(.+)$/
          [$1.constantize, $2]
        when /^(.+)(?:\.|::)(.+)$/
          [(class << $1.constantize; self; end), $2]
        else
          raise Error, "Bad target format: #{raw_target}"
        end
        instrument(obj, meth, &handler)
      end
    end  
    
    #######
    private
    #######

    def self.instrument(obj, meth, &handler)
      handlers << handler unless handlers.include?(handler)
      offset = handlers.size - 1
      code = wrapping meth, :instrument do |without|
        <<-CONTENTS
          # Invoke and time
          _start = Time.now
          _result = #{without}(*args, &block)
          _time = Time.now - _start
          # Call handler (don't change *args!)
          ::Fiveruns::Dash::Instrument.handlers[#{offset}].call(self, _time, *args)
          # Return the original result
          _result
        CONTENTS
      end
      obj.module_eval code
    rescue => e
      raise Error, "Could not attach (#{e.message})"
    end

    def self.wrapping(meth, feature)
      format = meth =~ /^(.*?)(\?|!|=)$/ ? "#{$1}_%s_#{feature}#{$2}" : "#{meth}_%s_#{feature}" 
      <<-DYNAMIC
        if instance_methods.include?("#{format % :without}")
          # Skip instrumentation
        else
          def #{format % :with}(*args, &block)
            #{yield(format % :without)}
          end
          alias_method_chain :#{meth}, :#{feature}
        end
      DYNAMIC
    end
      
  end
  
end