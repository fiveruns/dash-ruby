# This file contains implementations of rails custom objects for
# serialisation/deserialisation.

require 'fiveruns/json'

class Object
  def self.fjson_create(object)
    obj = new
    for key, value in object
      next if key == 'json_class'
      instance_variable_set "@#{key}", value
    end
    obj
  end

  def to_fjson(*a)
    result = {
      'json_class' => self.class.name
    }
    instance_variables.inject(result) do |r, name|
      r[name[1..-1]] = instance_variable_get name
      r
    end
    result.to_fjson(*a)
  end
end

class Symbol
  def to_fjson(*a)
    to_s.to_fjson(*a)
  end
end

module Enumerable
  def to_fjson(*a)
    to_a.to_fjson(*a)
  end
end

# class Regexp
#   def to_json(*)
#     inspect
#   end
# end
#
# The above rails definition has some problems:
#
# 1. { 'foo' => /bar/ }.to_json # => "{foo: /bar/}"
#    This isn't valid FiverunsJSON, because the regular expression syntax is not
#    defined in RFC 4627. (And unquoted strings are disallowed there, too.)
#    Though it is valid Javascript.
#
# 2. { 'foo' => /bar/mix }.to_json # => "{foo: /bar/mix}"
#    This isn't even valid Javascript.

