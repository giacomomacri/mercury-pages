require "mercury-pages/engine"
require 'mercury-pages/acts_as_editable'
require 'mercury-pages/acts_as_editor'
require 'mercury-pages/acts_as_assettable'
require 'mercury-pages/acts_as_asset'
require 'mercury-pages/controller_methods'
require 'mercury-pages/carrierwave_methods'

module MercuryPages
  EDITABLE_SUFFIX = '_editable'

  mattr_accessor :editor_class
  mattr_accessor :enable_elements_cache
  mattr_accessor :enable_custom_pages
  mattr_accessor :enable_pages_cache
  mattr_accessor :cached_pages_observed_classes
  mattr_accessor :paperclip_options
  mattr_accessor :carrierwave_versions

  @@paperclip_options = {}
  @@carrierwave_versions = {}
  @@cached_pages_observed_classes = []
  @@enable_elements_cache = true

  def self.setup
    yield self
    @@editor_class ||= ::PageElement  
    ActiveSupport.on_load(:mercury_pages_uploaders) do
      include MercuryPages::CarrierWaveMethods
    end
    require 'mercury-pages/mercury_pages_sweeper' if @@enable_pages_cache
  end

  def self.carrierwave_version(name, options = {}, &block)
    uploader = (options.delete(:uploader) || ImageUploader).to_s
    @@carrierwave_versions[uploader] ||= {}
    @@carrierwave_versions[uploader][name] = {:options => options, :block => block}
  end
end
