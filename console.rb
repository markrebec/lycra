#
# Used when launching an irb console to setup the environment
#

require 'byebug'
require 'awesome_print'
require 'active_record'
require 'lycra'

Dir[File.join(File.dirname(__FILE__), "app/models/**/*.rb")].each { |f| require f }
require File.join(File.dirname(__FILE__), "app/serializers/application_serializer.rb")
Dir[File.join(File.dirname(__FILE__), "app/serializers/**/*.rb")].each { |f| require f }
require File.join(File.dirname(__FILE__), "app/documents/application_document.rb")
Dir[File.join(File.dirname(__FILE__), "app/documents/**/*.rb")].each { |f| require f }

ActiveRecord::Base.establish_connection(
  YAML::load(File.open('config/database.yml'))['development']
)

ActiveRecord::Base.logger = Logger.new(STDOUT)

# configure this for models where we're testing direct elasticsearch integrations
Elasticsearch::Model.client = Elasticsearch::Client.new host: 'localhost', port: 9256

Lycra.configure do |config|
  config.elasticsearch_host = 'localhost'
  config.elasticsearch_port = 9256
end
