require 'routingfilter'

class ActionController::Base
  before_filter :set_theme_view_paths

  def set_theme_view_paths
    self.prepend_view_path File.join(File.dirname(__FILE__), "views")
  end

  # Note that set_view_paths is called by Alaveteli from the
  # rescue_action_in_public method, in order that error pages
  # may be themed correctly. Since whatdotheyknow-theme is a
  # primary theme that ought to style error pages, we define
  # this as an alias
  alias :set_view_paths :set_theme_view_paths
end

# Prepend the asset directories in this theme to the asset path:
%w(font stylesheets images javascripts).each do |asset_type|
  theme_asset_path = File.join(File.dirname(__FILE__), '..', 'assets', asset_type)
  Rails.application.config.assets.paths.unshift theme_asset_path
end

# In order to have the theme lib/ folder ahead of the main app one,
# inspired in Ruby Guides explanation: http://guides.rubyonrails.org/plugins.html
%w{ . }.each do |dir|
  path = File.join(File.dirname(__FILE__), dir)
  $LOAD_PATH.insert(0, path)
  ActiveSupport::Dependencies.autoload_paths << path
  ActiveSupport::Dependencies.autoload_once_paths.delete(path)
end

Rails.application.config.assets.precompile += %w(desig.js app.js)

# Monkey patch app code
for patch in [
  'patch_mailer_paths.rb',
  'controller_patches.rb',
  'model_patches.rb'
]
  require File.expand_path "../#{patch}", __FILE__
end

$alaveteli_route_extensions << 'custom-routes.rb'

# Tell FastGettext about the theme's translations: look in the theme's
# locale-theme directory for a translation in the first place, and if
# it isn't found, look in the Alaveteli locale directory next:
repos = [
  FastGettext::TranslationRepository.build('app', :path=>File.join(File.dirname(__FILE__), '..', 'locale-theme'), :type => :po),
  FastGettext::TranslationRepository.build('app', :path=>'locale', :type => :po)
]
FastGettext.add_text_domain 'app', :type=>:chain, :chain=>repos
FastGettext.default_text_domain = 'app'
