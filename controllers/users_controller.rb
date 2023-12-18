# frozen_string_literal: true

class Microblog < Sinatra::Base
  get '/users/:username' do
    username = params[:username]
    user = db_connection do |conn|
      conn.exec('SELECT * FROM users WHERE username = $1', [username])
    end.first
    jbuilder do |json|
      json.username user['username']
      json.created_at user['created_at']
    end
  end
end
