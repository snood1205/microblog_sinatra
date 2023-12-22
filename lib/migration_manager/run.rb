# frozen_string_literal: true

require 'pg'
require_relative '../../t'
require_relative '../lib/migration_manager'
require_relative 'helpers'
require_relative 'basic_connection'

module MigrationManager
  class Run < BasicConnection
    include Helpers

    attr_reader :conn

    def self.run(database_hash)
      instance = new(database_hash)
      instance.run_migrations
    ensure
      instance.conn.close
    end

    def run_migrations
      migrations.each do |migration|
        migration_number = derive_migration_number(migration)
        next if migration.include?('down.sql') ||
                (!latest_migration_number.nil? && migration_number <= latest_migration_number)

        run_migration migration
      end
    end

    private

    def run_migration(migration)
      exec_file_and_modify_migrations(migration, :insert)
    end
  end
end
