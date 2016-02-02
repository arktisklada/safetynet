$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "safetynet/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "safetynet"
  spec.version     = Safetynet::VERSION
  spec.authors     = ["arktisklada"]
  spec.email       = ["mail@enorganik.com"]
  spec.summary     = %q{Stop communication problems before they happen}
  spec.description = %q{Safetynet keeps track of email communications by user/email and ActionMailer message. If the same message is sent to the same user multiple times within the allowed timeframe, it will be blocked from delivery and notify system admins. The messages are filterable in a way similar to controller filters, and the checking method can be called by itself outside the normal hooks for additional throttling (i.e. SMS sending, push notifications, etc.). }
  spec.homepage    = "https://github.com/arktisklada/safetynet"
  spec.license     = "MIT"
  if File.exist?('UPGRADING.md')
    spec.post_install_message = File.read('UPGRADING.md')
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE.TXT", "Rakefile", "README.md"]
  spec.test_files = Dir["test/**/*"]

  spec.add_dependency "rails", "~> 4.0"

  spec.add_development_dependency 'sqlite3'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'pry-rails'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec'
end
