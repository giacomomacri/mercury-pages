module MercuryPages
  module CarrierWaveMethods
    extend ActiveSupport::Concern

    included do
      MercuryPages::carrierwave_versions[self].each do |v, config|
        version v, {:if => "#{v}_is_enabled?".to_sym}.merge(config[:options]), &config[:block]
        define_method "#{v}_is_enabled?".to_sym do |a|
          m = "allowed_#{model.class.name.underscore}_versions".to_sym
          if model.assettable && model.assettable.respond_to?(m)
            asset_image_versions = model.assettable.send(m, a)
            asset_image_versions && asset_image_versions.include?(v)
          else
            true
          end
        end
      end
    end

    module ClassMethods
    end
  end
end
