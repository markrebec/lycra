#
# Used when launching an irb console to setup the environment
#

require 'byebug'
require 'active_record'
require 'lycra'

Dir[File.join(File.dirname(__FILE__), "app/models/**/*.rb")].each { |f| require f }

ActiveRecord::Base.establish_connection(
  YAML::load(File.open('config/database.yml'))['development']
)

ActiveRecord::Base.logger = Logger.new(STDOUT)
