# frozen_string_literal: true

require 'optionparser'
require_relative 'lib/migration_manager'
require 'dotenv/load'

def database_url(options)
  user = options[:user] || ENV.fetch('DB_USER', nil)
  password = options[:password] || ENV.fetch('DB_PASSWORD', nil)
  host = options[:host] || ENV.fetch('DB_HOST', nil)
  port = options[:port] || ENV.fetch('DB_PORT', nil)
  database = options[:database] || ENV.fetch('DB_NAME', nil)
  "postgres://#{user}:#{password}@#{host}:#{port}/#{database}"
end

def migration_usage
  puts 'Usage: sql.rb migrations [action] [options]'
  puts 'Actions:'
  puts '  create [name]'
  puts '  run'
  puts '  rollback'
end

def handle_migrations(options)
  case ARGV.shift
  when 'create'
    MigrationManager::Create.run(ARGV.shift)
  when 'run'
    MigrationManager::Run.run(database_url(options))
  when 'rollback'
    MigrationManager::Rollback.run(database_url(options))
  else
    migration_usage
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: sql.rb [action] [options]'

  opts.on('-h', '--help', 'Help') do
    puts opts
    exit
  end

  opts.on('-H', '--host HOST', 'Host') { |v| options[:host] = v }
  opts.on('-u', '--user USER', 'User') { |v| options[:user] = v }
  opts.on('-p', '--password PASSWORD', 'Password') { |v| options[:password] = v }
  opts.on('-P', '--port PORT', 'Port') { |v| options[:port] = v }
  opts.on('-d', '--database DATABASE', 'Database') { |v| options[:database] = v }
end

action = ARGV.shift
case action
when 'migrations'
  handle_migrations(options)
when 'help'
  puts 'Usage: sql.rb [action] [options]'
else
  puts 'Usage: sql.rb [action] [options]'
  puts 'Actions:'
  puts '  migrations'
  puts '  help'
end
