# frozen_string_literal: true

require_relative 'helpers'

module MigrationManager
  class Create
    include Helpers

    def self.run(name)
      puts "Creating migration #{name}"
      latest_migration = Dir.glob('migrations/*/up.sql').max
      latest_migration_number = derive_migration_number(latest_migration)
      next_migration_number = latest_migration_number ? latest_migration_number + 1 : 1
      next_migration_name = "#{next_migration_number}_#{name}.sql"
      dir = File.dirname(__FILE__) + "/../migrations/#{next_migration_name}"
      Dir.mkdir(dir)
      File.touch("#{dir}/up.sql")
      File.touch("#{dir}/down.sql")
    end
  end
end
