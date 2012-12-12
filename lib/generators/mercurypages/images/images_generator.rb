module Mercurypages
  class ImagesGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def generate_models
      generate 'model', 'Asset type:string assettable_id:integer assettable_type:string title:string description:text priority:integer link:string target:string'
      generate 'paperclip', 'Asset content'
      inject_into_file 'app/models/asset.rb', :before => "end" do <<-RUBY
  include MercuryPages::ActsAsAsset
RUBY
      end
    end
  end
end
