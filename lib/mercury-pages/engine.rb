module MercuryPages
  class Engine < ::Rails::Engine
    initializer 'mercury_pages' do |app|
      if defined? Globalize
        Globalize::ActiveRecord::Translation.class_eval { attr_accessible :locale }
      end

      ActiveSupport.on_load(:action_controller) do
        include MercuryPages::ControllerMethods
      end
    end
  end
end
