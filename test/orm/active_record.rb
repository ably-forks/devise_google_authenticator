ActiveRecord::Migration.verbose = true
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Rails 8 compatible migration context
migrate_path = File.expand_path('../../rails_app/db/migrate', __FILE__)

# Use Rails-compatible migration approach
ActiveRecord::MigrationContext.new([migrate_path]).migrate
