# frozen_string_literal: true

require_relative '../database'
require_relative 'modifiable'
require_relative 'persistable'
require_relative 'queryable'

class BaseModel
  protected

  def initialize(attributes = {}, from_sql: false)
    attributes.each do |attribute, value|
      next unless from_sql || respond_to?("#{attribute}=")

      instance_variable_set("@#{attribute}", value)
    end
    @touched_attributes = []
  end
end
