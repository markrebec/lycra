#
# Used when launching an irb console to setup the environment
#

require 'byebug'
require 'active_record'
require 'lycra'

ActiveRecord::Base.establish_connection(
  YAML::load(File.open('config/database.yml'))['development']
)
