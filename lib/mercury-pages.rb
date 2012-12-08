require "mercury-pages/engine"
require 'mercury-pages/acts_as_editable'
require 'mercury-pages/acts_as_editor'
require 'mercury-pages/acts_as_assettable'
require 'mercury-pages/acts_as_asset'
require 'mercury-pages/controller_methods'

module MercuryPages
  EDITABLE_SUFFIX = '_editable'

  mattr_accessor :enable_elements_cache
  
  def self.setup
    yield self
  end
end
