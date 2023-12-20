# frozen_string_literal: true
require 'dotenv/load'
require 'pg'

module Database
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def db_connection
      connection = PG.connect(dbname: ENV.fetch('DB_NAME', nil), user: ENV.fetch('DB_USER', nil),
                              password: ENV.fetch('DB_PASSWORD', nil), host: ENV.fetch('DB_HOST', nil),
                              port: ENV.fetch('DB_PORT', nil))
      yield(connection)
    ensure
      connection&.close
    end
  end

  def transaction(stderr: true)
    raise ArgumentError, 'No block given' unless block_given?

    self.class.db_connection do |conn|
      conn.exec('BEGIN')
      yield(conn)
      conn.exec('COMMIT')
    rescue PG::Error => e
      warn "Error: #{e.message}" if stderr
      conn.exec('ROLLBACK')
    end
  end
end
