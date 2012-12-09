require "mercury-pages/engine"
require 'mercury-pages/acts_as_editable'
require 'mercury-pages/acts_as_editor'
require 'mercury-pages/acts_as_assettable'
require 'mercury-pages/acts_as_asset'
require 'mercury-pages/controller_methods'
require 'mercury-pages/carrierwave_methods'

module MercuryPages
  EDITABLE_SUFFIX = '_editable'

  mattr_accessor :enable_elements_cache
  mattr_accessor :paperclip_options
  mattr_accessor :carrierwave_versions
  
  @@paperclip_options = {}
  @@carrierwave_versions = {}

  def self.setup
    yield self
    @@carrierwave_versions.each do |uploader, version|
      uploader.send(:include, MercuryPages::CarrierWaveMethods)
    end
  end

  def self.carrierwave_version(name, options = {}, &block)
    uploader = options.delete(:uploader) || ImageUploader
    @@carrierwave_versions[uploader] ||= {}
    @@carrierwave_versions[uploader][name] = {:options => options, :block => block}
  end
end
