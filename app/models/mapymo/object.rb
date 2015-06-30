module Mapymo::Object
  extend ActiveSupport::Concern

  # Allow the object to be built from a hash of attributes.
  # e.g. Object.new(attr_name: 1, other_attr: 2)
  include ActiveModel::Model

  # Mapymo modules.
  include Mapymo::Persistence
  include Mapymo::Finders

  included do
    cattr_accessor :dynamodb_config
  end

  class_methods do
    # Public: Config builder.
    #
    # Example: The following produces identical config.
    #
    #   configure_mapymo do |config|
    #     config.hash_key = "myHashkey"
    #   end
    #
    #   configure_mapymo({ :hash_key => "myHashKey" })
    #
    # Sets the dynamodb_config on the class.
    def configure_mapymo(options = {}, &block)
      self.dynamodb_config = Mapymo::Config.new(self, options, &block)
    end

    # Public: Build the dynamodb key from a hash key and optional range key.
    # Returns a Hash representing the DynamoDB key.
    def dynamodb_key(hash_key, range_key = nil)
      key_hash = { dynamodb_config.hash_key => hash_key }
      key_hash.merge!({ dynamodb_config.range_key => range_key }) if dynamodb_config.range_key.present?
      key_hash
    end

    def from_dynamo(item)
      self.dynamodb_config.mapper.marshal_into_object(self, item)
    end
  end # end class_methods

  # Public: Get object values from DynamoDB attribute names.
  # Returns the attribute of the object that corresponds to the dynamodb_attr.
  def [](dynamodb_attr)
    object_attr = self.class.dynamodb_config.attribute_map[dynamodb_attr]
    object_attr.present? ? send(object_attr) : nil
  end

  # Public: Set object values from DynamoDB attribute names.
  # Returns the set value.
  def []=(dynamodb_attr, new_value)
    object_attr = self.class.dynamodb_config.attribute_map[dynamodb_attr]
    send("#{object_attr}=", new_value)
  end

  # Public: Load the object from the database with a consistent read.
  def reload
    self.dynamodb_config.mapper.load(self.class, self.hash_key, self.range_key, { consistent_read: true })
  end

  # Public: Get the DynamoDB key hash for this instance.
  #
  # Returns a Hash representing the DynamoDB key.
  def dynamodb_key
    self.class.dynamodb_key(hash_key, range_key)
  end

  # Public: Get the hash key value for this instance.
  def hash_key
    self[self.class.dynamodb_config.hash_key]
  end

  # Public: Get the range key value for this instance.
  def range_key
    self[self.class.dynamodb_config.range_key] if self.class.dynamodb_config.range_key.present?
  end

  # Public: Get equivalent DynamoDB item hash.
  def to_dynamo
    self.class.dynamodb_config.mapper.marshal_into_item(self)
  end

  # Public: Check if this object is equivalent to another object in DynamoDB.
  def dynamo_eql?(other)
    other.is_a?(self.class) && self.to_dynamo.eql?(other.to_dynamo)
  end

end
