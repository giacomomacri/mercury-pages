module MercuryPages
  module ActsAsAsset
    extend ActiveSupport::Concern
 
    included do
      belongs_to :assettable, :polymorphic => true
      attr_accessible :id, :created_at, :updated_at

      scope :by_type, lambda { |t| where(:type => t) }
    end
 
    module ClassMethods
      def acts_as_paperclip_asset(options = {})
        options[:styles] = lambda do |a|
          m = "allowed_#{self.name.underscore}_versions".to_sym
          s = nil
          if a.instance.assettable && a.instance.assettable.respond_to?(m)
            s = a.instance.assettable.send(m)
          end
          s || {}
        end
        has_attached_file :content, options

        attr_accessor :delete_content
        attr_accessible :content, :delete_content
        before_validation { self.content.clear if self.delete_content == '1' }

        if defined? RailsAdmin
          rails_admin do
            configure :content, :paperclip
          end
        end  
      end

      def acts_as_carrierwave_asset(*args)
        yield :content, :content_file_name

        attr_accessible :content, :content_cache, :remove_content

        if defined? RailsAdmin
          rails_admin do
            configure :content, :carrierwave
            configure :content_updated_at do
              hide
            end
          end
        end  
      end
    end
  end
end
