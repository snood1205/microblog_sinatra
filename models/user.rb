# frozen_string_literal: true

require_relative 'database_model'

class User < DatabaseModel
  include Modifiable
  include Queryable

  db_attributes :username
end
