module MercuryPages
  module ActsAsAssettable
    extend ActiveSupport::Concern
 
    module ClassMethods
      def has_one_asset(*args)
        options = args.extract_options!
        name = args[0] || :asset
        has_one name, :as => :assettable, :class_name => name.to_s.camelize, :dependent => :destroy, :inverse_of => :assettable
        accepts_nested_attributes_for name, :allow_destroy => true
        attr_accessible "#{name}_attributes".to_sym
      end

      def has_many_assets(*args)
        options = args.extract_options!
        name = args[0] || :assets
        has_many name, :as => :assettable, :order => 'assets.priority, assets.id', :class_name => name.to_s.singularize.camelize, :dependent => :destroy, :inverse_of => :assettable
        accepts_nested_attributes_for name, :allow_destroy => true
        attr_accessible "#{name}_attributes".to_sym
      end
    end
  end
end

ActiveRecord::Base.send :include, MercuryPages::ActsAsAssettable
