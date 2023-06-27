ActiveRecord::Migration.verbose = true
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::MigrationContext.new(File.expand_path('../../rails_app/db/migrate', __FILE__),
                                   ActiveRecord::SchemaMigration).migrate
