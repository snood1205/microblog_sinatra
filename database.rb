# frozen_string_literal: true

require 'dotenv/load'
require 'pg'

def db_connection
  connection = PG.connect(dbname: ENV.fetch('DB_NAME', nil), user: ENV.fetch('DB_USER', nil),
                          password: ENV.fetch('DB_PASSWORD', nil), host: ENV.fetch('DB_HOST', nil),
                          port: ENV.fetch('DB_PORT', nil))
  yield(connection)
ensure
  connection&.close
end
