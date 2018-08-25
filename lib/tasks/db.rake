require 'yaml'
require 'active_record'

namespace :db do
  env = ENV['LYCRA_ENV'] || 'development'
  db_config = YAML::load(File.open('config/database.yml'))[env]

  desc "Create the database"
  task :create do
    ActiveRecord::Base.establish_connection(db_config)
    if db_config['adapter'] == 'sqlite3'
      ActiveRecord::Base.connection # forces sqlite to create the empty db file
    else
      ActiveRecord::Base.connection.create_database(db_config["database"])
    end
    puts "Database created for env #{env}."
  end

  desc "Migrate the database"
  task :migrate do
    ActiveRecord::Base.establish_connection(db_config)
    ActiveRecord::MigrationContext.new("db/migrate/").migrate

    Rake::Task["db:schema:dump"].invoke
    puts "Database migrated for env #{env}."
  end

  desc "Drop the database"
  task :drop do
    ActiveRecord::Base.establish_connection(db_config)
    if db_config['adapter'] == 'sqlite3'
      File.unlink(db_config["database"]) rescue nil
    else
      ActiveRecord::Base.connection.drop_database(db_config["database"])
    end
    puts "Database deleted for env #{env}."
  end

  desc "Reset the database"
  task :reset => [:drop, :create, :migrate]

  namespace :schema do
    desc 'Create a db/schema.rb file that is portable against any DB supported by AR'
    task :dump do
      ActiveRecord::Base.establish_connection(db_config)
      require 'active_record/schema_dumper'
      filename = "db/schema.rb"
      File.open(filename, "w:utf-8") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end
  end
end
