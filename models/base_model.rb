# frozen_string_literal: true

require_relative '../database'

class BaseModel
  extend Database
  include Database

  class << self
    attr_accessor :db_model_name

    def inherited(subclass)
      super
      subclass.db_model_name = "#{subclass.name.downcase}s"
    end

    def db_attributes(*attributes, has_id: true, has_timestamps: true)
      attr_readers_for_db_attributes(attributes, has_id, has_timestamps)
      writers_for_db_attributes(attributes)
    end

    def find_by(attributes_with_values)
      where(attributes_with_values, limit: 1).first
    end

    def where(attributes_with_values, limit: nil, offset: nil)
      attributes, values = permitted_attributes_and_values attributes_with_values

      where_statement = prepare_where_statement values, attributes, limit, offset

      db_connection { |conn| conn.exec(where_statement, values).map { |row| new(row, from_sql: true) } }
    end

    private

    def attr_readers_for_db_attributes(attributes, has_id, has_timestamps)
      attr_reader :id if has_id
      attr_reader :created_at, :updated_at if has_timestamps
      attr_reader(*attributes)
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

    def writers_for_db_attributes(attributes)
      attributes.each do |attribute|
        define_method "#{attribute}=" do |value|
          instance_variable_set("@#{attribute}", value)
        end
      end
    end
  end

  def save
    db_connection do |conn|
      transaction do
        id ? update(conn) : insert(conn)
      end
    end
  end

  def clean?
    @touched_attributes.empty?
  end

  protected

  def initialize(attributes = {}, from_sql: false)
    attributes.each do |attribute, value|
      next unless from_sql || respond_to?("#{attribute}=")

      instance_variable_set("@#{attribute}", value)
    end
    @touched_attributes = []
  end

  private

  def attributes_for_exec(include_id: false)
    @touched_attributes
      .map { |attribute| instance_variable_get("@#{attribute}") }
      .tap { |attributes| attributes << id if include_id }
  end

  def insert(conn)
    columns_to_insert = @touched_attributes.join(', ')
    insert_statement = <<~SQL
      INSERT INTO #{self.class.db_model_name} (#{columns_to_insert})
      VALUES (#{@touched_attributes.length.times.map { |count| "$#{count + 1}" }})
    SQL
    conn.exec(insert_statement, attributes_for_exec)
  end

  def update(conn)
    dollar_sign_statement = @touched_attributes.map.with_index(1) do |attribute, index|
      "#{attribute} = $#{index}"
    end.join(",\n")
    update_statement = <<~SQL
      UPDATE #{self.class.db_model_name}
      SET #{dollar_sign_statement}
      WHERE id = $#{@touched_attributes.length + 1}
    SQL

    conn.exec(update_statement, attributes_for_exec(include_id: true))
  end
end
