# frozen_string_literal: true

module Persistable
  def self.included(base)
    raise ArgumentError, 'Persistable can only be included in a class inheriting from BaseModel' unless base < BaseModel

    base.extend(ClassMethods)
    base.class_eval do
      class << self
        attr_accessor :db_model_name
      end

      def self.inherited(subclass)
        super
        subclass.db_model_name = "#{subclass.name.downcase}s"
      end

      def initialize(*args, **kwargs)
        kwargs[:from_sql] = true if kwargs.empty? || kwargs[:from_sql].nil?
        super(*args, **kwargs)
      end
    end
  end

  module ClassMethods
    def db_attributes(*attributes, has_id: true, has_timestamps: true)
      attr_readers_for_db_attributes(attributes, has_id, has_timestamps)
      writers_for_db_attributes(attributes)
    end

    private

    def attr_readers_for_db_attributes(attributes, has_id, has_timestamps)
      attr_reader :id if has_id
      attr_reader :created_at, :updated_at if has_timestamps
      attr_reader(*attributes)
    end

    def writers_for_db_attributes(attributes)
      attributes.each do |attribute|
        define_method "#{attribute}=" do |value|
          instance_variable_set("@#{attribute}", value)
        end
      end
    end
  end
end