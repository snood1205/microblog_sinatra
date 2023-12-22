# frozen_string_literal: true

require_relative '../models/user'

class Microblog < Sinatra::Base
  get '/users/:username' do
    user = QuerySet[User]
             .fetch(:username, :created_at)
             .where(username: params[:username])
             .one!
    jbuilder do |json|
      json.username user.username
      json.created_at user.created_at
    end
  end
end
