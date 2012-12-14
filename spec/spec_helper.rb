require 'bundler/setup'

$LOAD_PATH.unshift(File.expand_path(File.join('..', 'lib'), File.dirname(__FILE__)))
require ::File.expand_path('../config/environment',  File.dirname(__FILE__))

require 'simplecov'

SimpleCov.start

require 'rspec/autorun'
require 'fake_glacier_endpoint'

TEST_DATA_PATH = File.expand_path('data', File.dirname(__FILE__))

RSpec.configure do |config|
end