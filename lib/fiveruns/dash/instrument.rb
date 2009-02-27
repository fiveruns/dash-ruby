module Fiveruns::Dash
  
  module Instrument
        
    class Error < ::NameError; end

    def self.handlers
      @handlers ||= []
    end
    
    # We hold onto the metrics themselves so we can dynamically call their
    # context_finders (which may be changed after instrumentation)
    def self.metrics
      @metrics ||= []
    end
    
    # Important: This does not de-instrument
    def self.clear
      handlers.clear
      metrics.clear
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
            [Fiveruns::Dash::Util.constantize($1), $2]
          when /^(.+)(?:\.|::)(.+)$/
            [(class << Fiveruns::Dash::Util.constantize($1); self; end), $2]
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
    
    def self.timing(handler, metric, obj, args, mark = nil, limit_to_within = nil, token = nil)
      original_context = Fiveruns::Dash::Context.context.dup
      contexts = ::Fiveruns::Dash.sync { metric.context_finder.call(obj, *args) }
      if token
        # token allows us to handle re-entrant timing, see e.g. ar_time
        Thread.current[token] = 0 if Thread.current[token].nil?
        Thread.current[token] = Thread.current[token] + 1
        start = Time.now
        begin
          result = yield
        ensure
          time = Time.now - start
          Thread.current[token] = Thread.current[token] - 1
          if Thread.current[token] == 0
            if !limit_to_within || (Thread.current[:dash_markers] || []).include?(limit_to_within)
              handler.call(contexts, obj, time, *args)
            end
          end
        end
        result
      else
        if mark
          Thread.current[:dash_markers] ||= []
          Thread.current[:dash_markers].push mark
        end
        start = Time.now
        begin
          result = yield
        ensure
          time = Time.now - start
          Thread.current[:dash_markers].pop if mark
          if !limit_to_within || (Thread.current[:dash_markers] || []).include?(limit_to_within)
            handler.call(contexts, obj, time, *args)
          end
        end
        result
      end
    ensure
      Fiveruns::Dash::Context.set original_context
    end
    
    #######
    private
    #######

    def self.instrument(obj, meth, options = {}, &handler)
      handlers << handler
      handler_offset = handlers.size - 1
      identifier = "instrument_#{handler.hash.abs}"
      if options[:metric]
        metrics << options[:metric]
        metric_offset = metrics.size - 1
      end
      code = wrapping meth, identifier do |without|
        if options[:exceptions]
          %(
            begin
              #{without}(*args, &block)
            rescue Exception => _e
              _sample = ::Fiveruns::Dash::Instrument.handlers[#{handler_offset}].call(_e, self, *args)
              ::Fiveruns::Dash.session.add_exception(_e, _sample)
              raise
            end
          )
        else
          %(
            ::Fiveruns::Dash::Instrument.timing(
              ::Fiveruns::Dash.handlers[#{handler_offset}],
              ::Fiveruns::Dash.metrics[#{metric_offset}],
              self, args,
              #{options[:mark_as] ? ":#{options[:mark_as]}" : 'nil'},
              #{options[:only_within] ? ":#{options[:only_within]}" : 'nil'},
              #{options[:reentrant_token] ? ":id#{options[:reentrant_token]}" : 'nil'}
            ) do
              #{without}(*args, &block)
            end
          )
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
      %(
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
        Fiveruns::Dash::Util.chain(self, :#{meth}, :#{feature})
      )
    end
      
  end
  
end