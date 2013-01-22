module MercuryPages
  module ActsAsAssettable
    extend ActiveSupport::Concern
 
    module ClassMethods
      def has_one_asset(*args, &block)
        options = args.extract_options!
        name = (args[0] || 'asset').to_s
        has_one name.to_sym, :as => :assettable, :class_name => (options[:class_name] || name).classify, :dependent => :destroy, :inverse_of => :assettable
        accepts_nested_attributes_for name.to_sym, :allow_destroy => true
        attr_accessible "#{name}_attributes".to_sym

        define_method "allowed_#{name}_versions".to_sym do |attachment = nil|
          block ? block.call(attachment) : options[:versions]
        end
      end

      def has_many_assets(*args, &block)
        options = args.extract_options!
        name = (args[0] || 'assets').to_s
        has_many name.to_sym, :as => :assettable, :order => 'assets.priority, assets.id', :class_name => (options[:class_name] || name).classify, :dependent => :destroy, :inverse_of => :assettable
        accepts_nested_attributes_for name.to_sym, :allow_destroy => true
        attr_accessible "#{name}_attributes".to_sym

        define_method "allowed_#{name.singularize}_versions".to_sym do |attachment = nil|
          block ? block.call(attachment) : options[:versions]
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, MercuryPages::ActsAsAssettable
