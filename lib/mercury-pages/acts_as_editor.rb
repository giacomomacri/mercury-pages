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

      attr_accessible :item, :id, :created_at, :updated_at

      after_create do |editor|
        if name.blank?
          update_attribute(:name, "activerecord_#{self.class.name.underscore}_#{id}")
        end
      end

      after_save do |editor|
        if MercuryPages.enable_elements_cache
          Rails.cache.delete("editor##{name}") if name.present?
          Rails.cache.delete("editor@#{slug}") if slug.present?
        end
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
            field :type
            field :name
            field :aasm_state
            field :title
          end
        end rescue nil
      end
    end
 
    module ClassMethods
      def get_by_name(name, create = nil)
        create = true if create.nil?
        block = Proc.new { create ? find_or_create_by_name(name) : find_by_name(name) }
        MercuryPages.enable_elements_cache ? Rails.cache.fetch("editor##{name}", &block) : block.call
      end

      def get_by_slug(slug)
        block = Proc.new { find_by_name(name) }
        MercuryPages.enable_elements_cache ? Rails.cache.fetch("editor@#{slug}", &block) : block.call
      end
    end

    def item_type=(t)
      source_class = t.to_s.classify.constantize
      if source_class.respond_to?(:base_class)
        base_class = source_class.base_class
        if base_class.attribute_names.include?('type')
          super(base_class.name)
        else
          super
        end
      else
        super
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
