class PagesController < ApplicationController
  layout :pages_layout
  helper_method :page_name, :page_template
  attr_reader :page_template

  def page_name
    "pages/#{params[:id]}".split('/').join('_')
  end

  def show
    render_page_template(params[:id])
  end

  def method_missing(m, *args, &block)
    render_page_template(m)
  end

  private

  def render_page_template(path)
    t = nil
    options = {}
    if MercuryPages::enable_custom_pages
      pe = MercuryPages.editor_class.published.where(:slug => path).first
      if pe && pe.partial.present?
        @page_template = pe
        options[:template] = pe.partial
        options[:layout] = pe.layout if pe.layout.present?
      end
    end
    options[:template] ||= "pages/#{path}"
    begin
      render options
    rescue ActionView::MissingTemplate => e
      raise Rails.env.development? ? e : ActionController::RoutingError.new(t)
    end    
  end

  def pages_layout
    if params[:layout] == 'false'
      false
    elsif params[:layout].present?
      params[:layout]
    else
      'application'
    end
  end
end
