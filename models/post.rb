# frozen_string_literal: true

require_relative 'base_model'

class Post < BaseModel
  db_attributes :title, :text, :user_id
end
