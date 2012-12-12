module MercuryPagesHelper
  def element_tag(*args, &block)
    with_editable_object(true, *args) do |name, field, e, options|
      instance_variable_set("@#{name.to_s.underscore}", e)

      offline = e.respond_to?(:'published?') ? !e.published? : false
      return if offline

      content = e.nil? ? nil : block ? capture(e, &block) : e.send(field)
      content.blank? ? empty_editable_tag(name, field) : raw(content)
    end
  end

  def mercury_element_tag(*args, &block)
    with_editable_object(true, *args) do |name, field, e, options|
      instance_variable_set("@#{name.to_s.underscore}", e)

      tag = options.delete(:tag) || :div
      options[:id] ||= "#{name}#{MercuryPages::EDITABLE_SUFFIX}"
      options[:'data-mercury'] ||= 'full'
      options[:class] = options[:class].to_s + ' mercury-pages-editable-element' if can_edit?

      offline = e.respond_to?(:'published?') ? !e.published? : false
      return if offline

      content = e.nil? ? nil : block ? capture(e, &block) : e.send(field)
      if options[:'data-mercury'] == 'image'
        image_tag(content.present? ? content : root_url, options)
      else
        content_tag(tag, content.blank? ? empty_editable_tag(name, field) : raw(content), options)
      end
    end
  end

  def element_list_tag(*args, &block)
    with_editable_object(false, *args) do |name, field, e, options|
      content = ''
      params = options.delete(:find) || {}
      params[:conditions] = (params[:conditions] || {}).merge(:list_name => name)
      MercuryPages::editor_class.published.find(:all, params).each_with_index do |pe, i|
        if block_given?
          content += capture(pe, i, &block)
        else
          default_partial = pe.partial.blank? ? (options[:default] || options[:page_elements] || pe.item_type.underscore || 'page_element') : pe.partial
          if p = options[pe.item_type.underscore.pluralize.to_sym]
            content += render(:partial => p == :inherit ? default_partial : p, :object => pe.item) if pe.item
          else
            content += render(:partial => default_partial, :object => pe.item || pe)
          end
        end
      end
      raw(content)
    end
  end

  def toggle_tag
    return unless can_edit?

    content_for :javascripts do
      javascript_tag(<<-EOF
        function toggleMercuryPages() {
          var cookie = readCookie();
          if (cookie == 'yes')
            removeCookie();
          else
            writeCookie('yes', 60);
          $('.mercury-pages-editable-element').toggleClass('outlined');
          $('.mercury-pages-tool').fadeToggle();
        }

        function writeCookie(value, duration) {
          var expires = new Date();
          var now = new Date();
          expires.setTime(now.getTime() + (parseInt(duration) * 60000));
          document.cookie = "mercury-pages-tool=" + escape(value) + '; expires=' + expires.toGMTString() + '; path=/';
        }

        function readCookie() {
          if (document.cookie.length > 0) {
            var start = document.cookie.indexOf("mercury-pages-tool=");
            if (start != -1) {
              start = start + "mercury-pages-tool".length + 1;
              var end = document.cookie.indexOf(";", start);
              if (end == -1) end = document.cookie.length;
              return unescape(document.cookie.substring(start, end));
            }
            else {
               return "";
            }
          }
          return "";
        }

        function removeCookie(name) {
          writeCookie('', -1);
        }

        $(function() {
          var cookie = readCookie();
          if (cookie == 'yes') {
            $('.mercury-pages-editable-element').addClass('outlined');
            $('.mercury-pages-tool').fadeIn();            
          }
          else {
            $('.mercury-pages-tool').fadeOut();
          }
        });
EOF
      )
    end
    content_tag(:span, class: 'mercury-pages-toggle') do
      link_to_function(t("mercury_pages.toggle"), "toggleMercuryPages(); return false;")
    end
  end

  def editor_tag
    return unless can_edit?

    content_tag(:span, class: 'mercury-pages-tool mercury-pages-edit') do
      link_to(t("mercury_pages.edit_in_line"), "/editor" + request.path, id: "mercury-pages-edit-link", data: { save_url: mercury_pages_update_path })
    end
  end

  def admin_tag(&block)
    return unless can_edit?

    content_tag(:span, class: 'mercury-pages-tool mercury-pages-manage', &block) rescue nil
  end

  def admin_path(*args)
    if args.nil?
      if defined? RailsAdmin
        rails_admin.dashboard_path
      end
    else
      with_editable_object(false, *args) do |name, field, e, options|
        action = options.delete(:action) || 'edit'
        e ||= MercuryPages::editor_class.get_by_name(name, false)
        clazz = e ? e.class.name : name.to_s
        if defined? RailsAdmin
          names = clazz.split("::").map { |n| n.underscore }
          # modules = names[0..-2]
          # class_name = names[-1]
          full_name = names.join('~')
          case action
          when 'new'
            rails_admin.new_path(full_name, options.merge(clazz => {:list_name => options.delete(:list_name)}))
          when 'delete' then rails_admin.delete_path(full_name, e, options)
          else
            rails_admin.edit_path(full_name, e, options)
          end
        end
      end
    end
  end

  private

  def with_editable_object(find_or_create, *args)
    args ||= []
    options = args.extract_options!
    e = args[0]
    field = options[:field] || 'content'
    create = options.delete(:create)
    element_class = options.delete(:element_class)
    element_class = element_class.to_s.constantize if element_class
    if e.is_a?(ActiveRecord::Base)
      name = "activerecord_#{e.class.name.underscore}_#{e.id}"
      name = "#{name}_#{options[:part]}" unless options[:part].blank?
      options[:'data-activerecord-class'] = e.class.name
      options[:'data-activerecord-id'] = e.id
    else
      name = args[0] || (controller_name == 'pages' ? page_name : "#{controller_name}_#{action_name}")
      name = "#{name}_#{options[:part]}" unless options[:part].blank?
      e = (element_class || MercuryPages::editor_class).get_by_name(name, find_or_create) # Find a Page Element unless bound to an AR model object
      if e
        options[:'data-activerecord-class'] = e.class.name
        options[:'data-activerecord-id'] = e.id
      end
    end
    if field.present? && field != 'content'
      options[:'data-activerecord-field'] = field
      name = "#{name}_#{field}"
    end
    yield name, field, e, options
  end

  def empty_editable_tag(name, field, options = {})
    if field
      content_tag(:span, t('mercury_pages.empty_element_field', :name => name, :field => field), :class => 'mercury-pages-empty')
    else
      content_tag(:span, t('mercury_pages.empty_element', :name => name), :class => 'mercury-pages-empty')
    end
  end
end
