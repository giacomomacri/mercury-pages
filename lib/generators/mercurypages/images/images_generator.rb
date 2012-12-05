module Mercurypages
  class ImagesGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def generate_models
      generate 'model', 'asset type:string assettable_id:integer assettable_type:string title:string priority:integer'
      generate 'paperclip', 'asset content'
      inject_into_file 'app/models/asset.rb', :before => "end" do <<-RUBY
  include MercuryPages::ActsAsAsset
RUBY
      end
    end
  end
end
