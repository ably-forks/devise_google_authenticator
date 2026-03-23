module DeviseGoogleAuthenticator
  class Engine < ::Rails::Engine # :nodoc:
    config.before_configuration do
      I18n.load_path += Dir[Engine.root.join('config', 'locales', '*.yml')]
    end

    ActiveSupport::Reloader.to_prepare do
      DeviseGoogleAuthenticator::Patches.apply
    end
  end
end
