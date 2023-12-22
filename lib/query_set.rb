# frozen_string_literal: true

require_relative 'database'
require_relative 'query_error'

class QuerySet
  include Database

  def self.[](model)
    new model
  end

  def execute
    query, values = @chained_queries.reduce(['', []]) do |(query, values), (next_query, next_values)|
      [query + next_query, values + next_values]
    end
    QuerySet.db_connection do |conn|
      result = conn.exec(query, values)
      result.map do |row|
        @model.new row, from_sql: true
      end
    end
  end

  # @param [Array<String|Symbol>] attributes
  def fetch(*attributes)
    validated_attributes = validate_attributes attributes
    select_clause = validated_attributes.empty? ? '*' : validated_attributes.join(', ')
    select_statement = <<~SQL
      SELECT #{select_clause}
        FROM #{@model.db_model_name}
    SQL
    @chained_queries << [select_statement, []]

    self
  end

  # @param [DatabaseModel] other_model
  # @param [Hash] on
  def join(other_model, on:)
    join_statement = <<~SQL
      INNER JOIN #{other_model.db_model_name}
      ON #{dollar_statement_from_on on}
    SQL
    @chained_queries << [join_statement, on.first]
    self
  end

  def limit(limit)
    @chained_queries << ["LIMIT $#{dollar_sign!}", [limit]]
    self
  end

  def offset(offset)
    raise QueryError, 'Offset must be used with limit' unless @chained_queries.last&.first&.include?('LIMIT')

    @chained_queries << ["OFFSET $#{dollar_sign!}", [offset]]
    self
  end

  def one!
    result = limit(1).execute
    raise QueryError, 'No results found' if result.empty?
    raise QueryError, 'Multiple results found' if result.length > 1

    result.first
  end

  # @param [DatabaseModel] other_model
  # @param [Hash] on
  def left_join(other_model, on:)
    join_statement = <<~SQL
      LEFT JOIN #{other_model.db_model_name}
      ON #{dollar_statement_from_on on}
    SQL
    @chained_queries << [join_statement, on.first]
    self
  end

  def where(attributes_with_values)
    validated_attributes = validate_attributes attributes_with_values.keys
    validated_attributes_with_values = attributes_with_values.slice(*validated_attributes)

    where_statement = prepare_where_statement validated_attributes_with_values.keys

    @chained_queries << [where_statement, validated_attributes_with_values.values]
    self
  end

  private

  attr_reader :model

  # @param [DatabaseModel] model
  def initialize(model)
    @model = model
    @dollar_sign_counter = 0
    @chained_queries = []
  end

  # @param [Hash] on
  def dollar_statement_from_on(on)
    on.length.times.map { "#{dollar_sign!} = #{dollar_sign!}" }.join(' AND ')
  end

  def dollar_sign!
    @dollar_sign_counter += 1
  end

  def prepare_where_statement(attributes)
    dollar_sign_statement = attributes.map do |attribute|
      "#{attribute} = $#{dollar_sign!}"
    end.join("\nAND ")
    <<~SQL
      WHERE #{dollar_sign_statement}
    SQL
  end

  def validate_attributes(attributes)
    attributes.filter do |attribute|
      model.instance_methods.include? attribute
    end
  end
end
