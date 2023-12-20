# frozen_string_literal: true

require_relative '../database'

module Queryable
  def self.included(base)
    raise ArgumentError, 'Queryable can only be included in a class inheriting from BaseModel' unless base < BaseModel

    base.extend ClassMethods
    base.include Database
  end

  module ClassMethods
    def find_by(attributes_with_values)
      where(attributes_with_values, limit: 1).first
    end

    def where(attributes_with_values, limit: nil, offset: nil)
      attributes, values = permitted_attributes_and_values attributes_with_values

      where_statement = prepare_where_statement values, attributes, limit, offset

      db_connection { |conn| conn.exec(where_statement, values).map { |row| new(row, from_sql: true) } }
    end

    private

    def permitted_attributes_and_values(attributes_with_values)
      attributes = []
      values = []
      attributes_with_values.each do |attribute, value|
        if instance_methods.include?(:"#{attribute}=")
          attributes << attribute
          values << value
        end
      end
      [attributes, values]
    end

    def prepare_where_statement(values, attributes, limit, offset)
      dollar_sign_statement = attributes.map.with_index(1) do |attribute, index|
        "#{attribute} = $#{index}"
      end.join("\nAND ")
      where_statement = <<~SQL
        SELECT *
        FROM #{db_model_name}
        WHERE #{dollar_sign_statement}
      SQL
      handle_limit_and_offset(values, where_statement, limit, offset)
    end

    def handle_limit_and_offset(values, where_statement, limit, offset)
      if limit
        where_statement += "LIMIT $#{values.length + 1}"
        values << limit
      end
      if offset
        where_statement += "\n" if limit
        where_statement += "OFFSET $#{values.length + 1}"
        values << offset
      end
      where_statement
    end
  end
end
