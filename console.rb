#
# Used when launching an irb console to setup the environment
#

require 'byebug'
require 'awesome_print'
require 'active_record'
require 'lycra'

Dir[File.join(File.dirname(__FILE__), "app/models/**/*.rb")].each { |f| require f }
Dir[File.join(File.dirname(__FILE__), "app/documents/**/*.rb")].each { |f| require f }

ActiveRecord::Base.establish_connection(
  YAML::load(File.open('config/database.yml'))['development']
)

ActiveRecord::Base.logger = Logger.new(STDOUT)

Elasticsearch::Model.client = Elasticsearch::Client.new host: 'localhost', port: 9256
