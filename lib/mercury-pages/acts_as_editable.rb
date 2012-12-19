module MercuryPages
  module ActsAsEditable
    extend ActiveSupport::Concern
 
    included do
    end
 
    module ClassMethods
      def acts_as_editable(options = {})
        attr_accessor :list_name

        has_many :page_elements, :as => :item, :class_name => MercuryPages.editor_class, :order => 'priority, id', :dependent => :destroy, :inverse_of => :item

        accepts_nested_attributes_for :page_elements, :allow_destroy => true
        attr_accessible :id, :created_at, :updated_at, :list_name, :page_elements_attributes

        after_create do |i|
          if i.list_name.present?
            MercuryPages::editor_class.create(:name => "#{i.list_name}-#{self.class.name.underscore}-#{i.id}", :list_name => i.list_name, :item_id => self.id, :item_type => self.class.name)
          end
        end

        # if defined? RailsAdmin
        #   rails_admin do
        #     configure :list_name, :hidden
        #   end
        # end
      end
    end
  end
end

ActiveRecord::Base.send :include, MercuryPages::ActsAsEditable
