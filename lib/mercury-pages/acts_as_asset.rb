module MercuryPages
  module ActsAsAsset
    extend ActiveSupport::Concern
 
    included do
      belongs_to :assettable, :polymorphic => true
      attr_accessible :id, :created_at, :updated_at

      scope :by_type, lambda { |t| where(:type => t) }
    end
 
    module ClassMethods
      def acts_as_paperclip_asset(*args)
        options = args.extract_options!
        options[:styles] = lambda do |a|
          m = "allowed_#{self.name.underscore}_versions".to_sym
          asset_image_versions = nil
          if a.instance.assettable && a.instance.assettable.respond_to?(m)
            asset_image_versions = a.instance.assettable.send(m, a)
          end
          all_versions = MercuryPages::paperclip_options[:styles] || {}
          if asset_image_versions
            all_versions.select { |k, v| asset_image_versions.include? k }
          else
            all_versions
          end
        end
        has_attached_file :content, MercuryPages::paperclip_options.merge(options)

        attr_accessor :delete_content
        attr_accessible :content, :delete_content, :content_file_name, :content_content_type, :content_file_size, :link, :target, :content_updated_at
        before_validation { self.content.clear if self.delete_content == '1' }
      end

      def acts_as_carrierwave_asset(*args)
        options = args.extract_options!
        uploader = args[0] || ImageUploader
        mount_uploader :content, uploader, :mount_on => :content_file_name

        attr_accessible :content, :content_cache, :remove_content, :content_file_name, :content_content_type, :content_file_size, :link, :target, :content_updated_at
      end

      def download(url)
        uri = URI(url)
        response = Net::HTTP.get_response(uri)
        if response.is_a?(Net::HTTPSuccess)
          if response['Content-Disposition'] && response['Content-Disposition'].match(/filename="(.+)"/i)
            filename = $1
          else
            filename = url
          end
          extname = File.extname(filename)
          basename = File.basename(filename, extname)
          Tempfile.open([basename, extname]) do |f|
            f.binmode
            f.write(response.body)
            f.rewind
            yield f
          end
        end
      end
    end

    def assettable_type=(t)
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
  end
end
