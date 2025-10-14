module DeviseGoogleAuthenticator
  class Engine < ::Rails::Engine # :nodoc:
    # Load locale files
    config.before_configuration do
      I18n.load_path += Dir[Engine.root.join('config', 'locales', '*.yml')]
    end

    # Rails 5+ uses ActiveSupport::Reloader, older versions use ActionDispatch::Callbacks
    (DeviseGoogleAuthenticator.rails5_or_newer? ? ActiveSupport::Reloader : ActionDispatch::Callbacks).to_prepare do
      DeviseGoogleAuthenticator::Patches.apply
    end
  end
end
