module DynamoDB::ORM
  extend ActiveSupport::Concern
  # Allow the object to be built from a hash of attributes.
  # e.g. Object.new(attr_name: 1, other_attr: 2)
  include ActiveModel::Model

  module ClassMethods
    cattr_accessor :dynamodb_config

    # Public: Config builder.
    #
    # Example:
    #   configure_dynamodb do |config|
    #      config.hash_key = "myTableHashKey"
    #      config.attribute_map = { "myTableHashKey" => :id }
    #   end
    #
    # Sets the dynamodb_config on the class.
    def configure_dynamodb(&block)
      self.dynamodb_config = ensure_valid_config(DynamoDB::ORM::Config.new(&block))
      self.dynamodb_config.table_name ||= self.name.pluralize
    end

    private

    # Internal: Validate the config.
    def ensure_valid_config(config)
      raise DynamoDB::ORM::Config::Error.new("attribute_map is required") unless config.attribute_map.present?
      raise DynamoDB::ORM::Config::Error.new("primary_key is required") unless config.hash_key.present?

      config.attribute_map.each do |dynamodb_attr, object_attr|
        unless self.method_defined?(object_attr) && self.method_defined?("#{object_attr}=")
          raise DynamoDB::ORM::Config::Error.new("Expected attr_accessor methods for #{object_attr} to map #{dynamodb_attr}")
        end
      end
      config
    end

  end

  # Public: DynamoDB::ORM::Config builder class.
  class Config
    attr_accessor :table_name, :hash_key, :range_key, :attribute_map
    def initialize
      yield(self)
    end

    # Public: DynamoDB::ORM::Config::Error.
    class Error < RuntimeError
    end
  end

end
