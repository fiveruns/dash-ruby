# Private copy of JSON for FiveRuns Dash as the current state of JSON/Ruby is
# nightmarish for library authors.  ActiveSupport and JSON have incompatability
# issues and supporting/fixing them is not worth it.
#
require 'fiveruns/json/version'
require 'fiveruns/json/common'
require 'fiveruns/json/pure/parser'
require 'fiveruns/json/pure/generator'
require 'fiveruns/json/pure'
require 'fiveruns/json/add/core'
require 'fiveruns/json/add/rails'