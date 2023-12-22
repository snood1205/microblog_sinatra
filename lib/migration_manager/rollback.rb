# frozen_string_literal: true

require_relative 'basic_connection'

module MigrationManager
  class Rollback < BasicConnection
    include Helpers

    def self.run(database_hash)
      instance = new(database_hash)
      instance.run_rollback
    ensure
      instance.conn.close
    end

    def run_rollback
      return unless latest_migration_number

      latest_migration = migrations.reverse.find do |migration|
        derive_migration_number(migration) == latest_migration_number && migration.include?('down.sql')
      end

      warn 'No rollback for latest migration' unless latest_migration

      rollback_migration latest_migration
    end

    private

    def rollback_migration(migration)
      exec_file_and_modify_migrations(migration, :delete)
    end
  end
end
