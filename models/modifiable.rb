# frozen_string_literal: true

module Modifiable
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
