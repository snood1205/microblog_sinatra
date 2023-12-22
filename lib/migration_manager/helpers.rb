# frozen_string_literal: true

require_relative '../../abase'

module MigrationManager
  module Helpers
    include ::Database
    def derive_migration_number(latest_migration) = latest_migration&.split('/')&.[](-2)&.split('_')&.first.to_i

    def exec_file_and_modify_migrations(migration, sql_action, print: true)
      migration_name = migration.split('/')[-2].chomp('.sql')
      sequence, name = migration_name.split('_', 2)
      print_from_action(sql_action, migration_name) if print
      transaction do
        conn.exec(File.read(migration))
        conn.exec(derive_sql_statement_from_action(sql_action), [name, sequence])
      end
    end

    private

    def derive_sql_statement_from_action(sql_action)
      case sql_action
      when :delete
        'DELETE FROM migrations WHERE name = $1 AND sequence = $2'
      when :insert
        'INSERT INTO migrations (name, sequence) VALUES ($1, $2)'
      else
        raise ArgumentError, "Unknown action #{sql_action}"
      end
    end

    def print_from_action(sql_action, migration_name)
      case sql_action
      when :delete
        puts "Rolling back migration #{migration_name}"
      when :insert
        puts "Running migration #{migration_name}"
      else
        raise ArgumentError, "Unknown action #{sql_action}"
      end
    end
  end
end
