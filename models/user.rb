# frozen_string_literal: true

require_relative 'base_model'

class User < BaseModel
  db_attributes :username
end
