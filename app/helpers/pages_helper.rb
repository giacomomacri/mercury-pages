module PagesHelper
  def with_template(t)
    yield
    render :template => t
  end

  def image_holder_tag(size)
    content_tag(:img, nil, :'data-src' => "holder.js/#{size}")    
  end
end
