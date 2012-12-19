class MercuryPagesSweeper < ActionController::Caching::Sweeper
  observe MercuryPages.cached_pages_observed_classes << MercuryPages.editor_class

  def after_create(e)
    expire_cache_for(e)
  end
 
  def after_update(e)
    expire_cache_for(e)
  end
 
  def after_destroy(e)
    expire_cache_for(e)
  end
 
  private

  def expire_cache_for(e)
    Rails.cache.clear
  end
end
