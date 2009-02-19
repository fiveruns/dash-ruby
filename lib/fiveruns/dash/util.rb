module Fiveruns::Dash
  
  # Utility methods, largely extracted from ActiveSupport
  module Util
    
    def self.demodulize(str)
      str.sub(/.*::/, '')
    end
    
    def self.shortname(str)
      underscore(demodulize(str))
    end
    
    # Note: Doesn't do any fancy Inflector-style modifications
    def self.titleize(str)
      underscore(str.to_s).split(/[_]+/).map { |s| s.capitalize }.join(' ')
    end

    def self.underscore(str)
      str.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
    
    def self.blank?(obj)
      obj.respond_to?(:empty?) ? obj.empty? : !self
    end
    
    def self.constantize(str)
      names = str.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end
    
    # ActiveSupport's alias_method_chain (but from outside the module)
    # Note: We'd love to use something other than AMC, but it's the 
    #       most consistent wrapper we know of that doesn't require
    #       cooperation from the target.
    def self.chain(mod, target, feature)
      # Strip out punctuation on predicates or bang methods since
      # e.g. target?_without_feature is not a valid method name.
      aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
      yield(aliased_target, punctuation) if block_given?

      with_method, without_method = "#{aliased_target}_with_#{feature}#{punctuation}",
                                    "#{aliased_target}_without_#{feature}#{punctuation}"

      mod.send(:alias_method, without_method, target)
      mod.send(:alias_method, target, with_method)

      case
      when mod.public_method_defined?(without_method)
        mod.instance_eval %(public :#{target})
      when mod.protected_method_defined?(without_method)
        mod.instance_eval %(protected :#{target})
      when mod.private_method_defined?(without_method)
        mod.instance_eval %(private :#{target})  
      end
    end
    
    def self.version_info
      if defined?(Gem)
        "with gems #{Gem.loaded_specs.values.find_all {|spec| spec.name =~ /fiveruns-dash/ }.map {|spec| "#{spec.name}-#{spec.version}"}.inspect}"
      else
        Fiveruns::Dash::Version::STRING
      end
    end
  end
  
end