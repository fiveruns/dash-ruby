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
        begin
          obj, meth = case raw_target
          when /^(.+)#(.+)$/
            [$1.constantize, $2]
          when /^(.+)(?:\.|::)(.+)$/
            [(class << $1.constantize; self; end), $2]
          else
            raise Error, "Bad target format: #{raw_target}"
          end
          instrument(obj, meth, options, &handler)
        rescue Fiveruns::Dash::Instrument::Error => em
          raise em
        rescue => e
          Fiveruns::Dash.logger.error "Unable to instrument '#{raw_target}': #{e.message}"
          Fiveruns::Dash.logger.error e.backtrace.join("\n\t")
        end
      end
    end

    def self.reentrant_timing(token, offset, this, args)
      # token allows us to handle re-entrant timing, see e.g. ar_time
      Thread.current[token] = 0 if Thread.current[token].nil?
      Thread.current[token] = Thread.current[token] + 1
      begin
        start = Time.now
        result = yield
      ensure
        time = Time.now - start
        Thread.current[token] = Thread.current[token] - 1
        if Thread.current[token] == 0
          ::Fiveruns::Dash::Instrument.handlers[offset].call(this, time, *args)
        end
      end
      result
    end
    
    def self.timing(offset, this, args)
      start = Time.now
      begin
        result = yield
      ensure
        time = Time.now - start
        ::Fiveruns::Dash::Instrument.handlers[offset].call(this, time, *args)
      end
      result
    end
    
    #######
    private
    #######

    def self.instrument(obj, meth, options = {}, &handler)
      handlers << handler unless handlers.include?(handler)
      offset = handlers.size - 1
      identifier = "instrument_#{handler.hash.abs}"
      code = wrapping meth, identifier do |without|
        if options[:exceptions]
          <<-EXCEPTIONS
            begin
              #{without}(*args, &block)
            rescue Exception => _e
              _sample = ::Fiveruns::Dash::Instrument.handlers[#{offset}].call(_e, self, *args)
              ::Fiveruns::Dash.session.add_exception(_e, _sample)
              raise
            end
          EXCEPTIONS
        elsif options[:reentrant_token]
          <<-REENTRANT
            ::Fiveruns::Dash::Instrument.reentrant_timing(:id#{options[:reentrant_token]}, #{offset}, self, args) do
              #{without}(*args, &block)
            end
          REENTRANT
        else
          <<-PERFORMANCE
            ::Fiveruns::Dash::Instrument.timing(#{offset}, self, args) do
              #{without}(*args, &block)
            end
          PERFORMANCE
        end
      end
      obj.module_eval code, __FILE__, __LINE__
      identifier
    rescue SyntaxError => e
      puts "Syntax error (#{e.message})\n#{code}"
      raise
    rescue => e
      raise Error, "Could not attach (#{e.message})"
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