module MercuryPages
  module ActsAsEditor
    extend ActiveSupport::Concern
 
    included do
      include AASM
      aasm do
        state :draft
        state :online, :initial => true
        state :offline
      end

      belongs_to :item, :polymorphic => true

      scope :by_item_type, lambda { |t| where(:item_type => t) }
      scope :by_element_type, lambda { |t| where(:element_type => t) }
      scope :by_list_name, lambda { |l| where(:list_name => l) }
      scope :valid, lambda { where('(valid_from IS NULL OR valid_from <= :now) AND (valid_until IS NULL OR valid_until >= :now)', :now => DateTime.now) }
      scope :published, online.valid
      default_scope order('priority')
      
      translates :title, :description, :content
      accepts_nested_attributes_for :translations, :allow_destroy => true

      attr_accessible :item, :translations_attributes, :id, :created_at, :updated_at

      after_save do |editor|
        Rails.cache.delete("editor##{editor.name}") if MercuryPages.enable_elements_cache
      end

      if defined? RailsAdmin
        rails_admin do
          configure :content, :text do
            bootstrap_wysihtml5 true
          end
          configure :type do
            hide
          end
          list do
            field :name
            field :aasm_state
            field :title
          end
        end
      end
    end
 
    module ClassMethods
      def get_by_name(name, create = nil)
        create = true if create.nil?
        block = Proc.new { create ? find_or_create_by_name(name) : find_by_name(name) }
        MercuryPages.enable_elements_cache ? Rails.cache.fetch("editor##{name}", &block) : block.call        
      end
    end

    def published?
      if item && item.respond_to?(:published)
        item.published?
      else
        now = DateTime.now
        online? && (valid_from.nil? || valid_from <= now) && (valid_until.nil? || valid_until >= now)
      end
    end

    def aasm_state_enum
      self.class.aasm_states_for_select
    end

    def partial_enum
      item && item.respond_to?(:partial_enum) ? item.partial_enum : []
    end

    def list_name_enum
      []
    end

    def to_s
      content
    end

    def method_missing(m, *args, &block)
      if item
        item.send(m, *args, &block)
      else
        super
      end
    end
  end
end
