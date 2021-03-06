# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require "rspec"
require "rspec/rails"
require "pry"
require "safetynet"

RSpec.configure do |config|
  config.after(:each) do
    ActionMailer::Base.deliveries.clear
    Safetynet::History.delete_all
  end
end
