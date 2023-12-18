# frozen_string_literal: true

module MigrationManager
  class BasicConnection
    attr_reader :conn

    protected

    attr_reader :latest_migration_number, :migrations, :latest_migration_name

    def initialize(database_hash)
      @conn = PG.connect database_hash
      derive_latest_migration!
      @migrations = Dir[Root.join('sql/migrations/*/{up,down}.sql')]
    end

    def derive_latest_migration!
      latest_migration = conn.exec('SELECT (name, sequence) FROM migrations ORDER BY created_at DESC LIMIT 1').first
      return unless latest_migration

      /\((?<name>\w+),(?<sequence>\d+)\)/.match latest_migration['row'] do |match|
        @latest_migration_number = match[:sequence].to_i
        @latest_migration_name = match[:name]
      end
    end
  end
end
