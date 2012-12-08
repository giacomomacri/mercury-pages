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
        attr_accessible :content, :delete_content, :content_file_name, :content_content_type, :content_file_size, :link, :target, :content_updated_at
        before_validation { self.content.clear if self.delete_content == '1' }
      end

      def acts_as_carrierwave_asset(*args)
        yield :content, :content_file_name

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
  end
end
