ENV['RAILS_ENV'] = 'test'

require 'simplecov' if ENV["COVERAGE"] == "true"

Dir["#{File.expand_path('../../step_definitions', __FILE__)}/*.rb"].each do |f|
  require f
end

require_relative "../../spec/rails/rails-#{Gem.loaded_specs["rails"].version}/config/environment"

require_relative 'rails'

require 'rspec/mocks'
World(RSpec::Mocks::ExampleMethods)

Around do |scenario, block|
  RSpec::Mocks.setup

  block.call

  begin
    RSpec::Mocks.verify
  ensure
    RSpec::Mocks.teardown
  end
end

After '@debug' do |scenario|
  # :nocov:
  save_and_open_page if scenario.failed?
  # :nocov:
end

require 'capybara/rails'
require 'capybara/cucumber'
require 'capybara/session'

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.load_selenium

  options = Selenium::WebDriver::Chrome::Options.new
  options.args << '--headless'

  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.read_timeout = 180

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, http_client: http_client)
end

Capybara.javascript_driver = :chrome

Capybara.server = :webrick

Capybara.asset_host = 'http://localhost:3000'

# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.
Capybara.default_selector = :css

# If you set this to false, any error raised from within your app will bubble
# up to your step definition and out to cucumber unless you catch it somewhere
# on the way. You can make Rails rescue errors and render error pages on a
# per-scenario basis by tagging a scenario or feature with the @allow-rescue tag.
#
# If you set this to true, Rails will rescue all errors and render error
# pages, more or less in the same way your application would behave in the
# default production environment. It's not recommended to do this for all
# of your scenarios, as this makes it hard to discover errors in your application.
ActionController::Base.allow_rescue = false

# Database resetting strategy
DatabaseCleaner.strategy = :truncation
Cucumber::Rails::Database.javascript_strategy = :truncation

# Warden helpers to speed up login
# See https://github.com/plataformatec/devise/wiki/How-To:-Test-with-Capybara
include Warden::Test::Helpers

After do
  Warden.test_reset!
end

Before do
  # We are caching classes, but need to manually clear references to
  # the controllers. If they aren't clear, the router stores references
  ActiveSupport::Dependencies.clear

  # Reload Active Admin
  ActiveAdmin.unload!
  ActiveAdmin.load!
end

# Force deprecations to raise an exception.
ActiveSupport::Deprecation.behavior = :raise

After '@authorization' do |scenario, block|
  # Reset back to the default auth adapter
  ActiveAdmin.application.namespace(:admin).
    authorization_adapter = ActiveAdmin::AuthorizationAdapter
end

Around '@silent_unpermitted_params_failure' do |scenario, block|
  original = ActionController::Parameters.action_on_unpermitted_parameters

  begin
    ActionController::Parameters.action_on_unpermitted_parameters = false
    block.call
  ensure
    ActionController::Parameters.action_on_unpermitted_parameters = original
  end
end

Around '@locale_manipulation' do |scenario, block|
  I18n.with_locale(:en, &block)
end
