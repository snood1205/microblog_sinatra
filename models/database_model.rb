# frozen_string_literal: true

require_relative 'base_model'
require_relative '../lib/query_set'

class DatabaseModel < BaseModel
  include Persistable
end
