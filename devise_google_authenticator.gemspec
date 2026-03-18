$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name = "devise_google_authenticator"
  s.version = "0.5.0"
  s.authors = ["Christian Frichot"]
  s.date = "2016-08-12"
  s.description = "Devise Google Authenticator Extension, for adding Google's OTP to your Rails apps!"
  s.email = "xntrik@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = Dir["{app,config,lib}/**/*"] + %w[LICENSE.txt README.rdoc]
  s.homepage = "http://github.com/AsteriskLabs/devise_google_authenticator"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.summary = "Devise Google Authenticator Extension"

  s.required_ruby_version = '>= 3.0.0'
  # s.required_rubygems_version = '>= 2.1.0'

  s.add_runtime_dependency 'devise', '~> 5.0'
  s.add_runtime_dependency 'rotp', '>= 1.6'
  s.add_runtime_dependency 'rqrcode', '>= 0.10.1'
end
