class Mapymo::Mapper

  cattr_accessor :mapped_classes

  class Error < RuntimeError; end

  # Public: Constructor
  def initialize(dynamo_db_client, dynamo_db_mapper_config = nil)
    @dynamo_db_client = dynamo_db_client
    @dynamo_db_mapper_config = dynamo_db_mapper_config

    unless @dynamo_db_client.is_a?(Aws::DynamoDB::Client)
      raise Mapper::Error.new("Expected #{Aws::DynamoDB::Client} but got #{@dynamo_db_client.class}")
    end
  end

  # Public: Marshal a get item output into an object of type object_class.
  #
  # object_class - The class of the object to marshal into.
  # item - The item hash to marshal into an object.
  # attribute_map - (optional) The attribute map to use when marshalling.
  #
  # Returns an instance of object_class.
  def marshal_into_object(object_class, item, attribute_map = object_class.dynamodb_config.attribute_map)
    return nil if item.nil?

    item_attribute_hash = {}
    attribute_map.each { |dynamo_attr, object_attr| item_attribute_hash[object_attr] = item[dynamo_attr] }

    begin
      object_class.new(item_attribute_hash)
    rescue NoMethodError => e
      raise Mapper::Error.new("Unable to marshal #{item} into #{object_class} using attribute map #{attribute_map}, #{e.message}")
    end
  end

  # Public: Reverse operation of marshal_into_object.
  #
  # object - The object to marshal into an item.
  # attribute_map - (optional) The attribute map to use when marshalling.
  #
  # Returns a dynamo db item hash.
  def marshal_into_item(object, attribute_map = object.class.dynamodb_config.attribute_map)
    item_hash = {}
    begin
      attribute_map.each { |dynamo_attr, object_attr| item_hash[dynamo_attr] = object.send(object_attr) }
    rescue NoMethodError => e
      raise Mapper::Error.new("Unable to marshal #{object.inspect} into item using attribute_map #{attribute_map}")
    end
    item_hash
  end

  # Public: Load object from DynamoDB and serialize into the item of object.
  #
  # hash_key - The hash key of the object.
  # range_key - (option) The range key of the object.
  # options - (optional) The same as options to Aws::DynamoDB::Client#get_item
  #
  def load(object_class, hash_key, range_key = nil, get_item_options = {})
    key_options = { object_class.dynamodb_config.hash_key => hash_key }
    key_options.merge!({ object_class.dynamodb_config.range_key => range_key }) if range_key.present?

    result = @dynamo_db_client.get_item(get_item_options.merge({ key: key_options,
                                                                 table_name: object_class.dynamodb_config.table_name }))
    marshal_into_object(object_class, result.item)
  end

  # Public: Save the given object.
  #
  # hash_key - The object to save.
  # put_item_options - An options hash for Aws::DynamoDB::Client#put_item.
  #
  # Returns PutItemOutput.
  def save(object, put_item_options = {})
    @dynamo_db_client.put_item(put_item_options.merge({ item: marshal_into_item(object),
                                                        table_name: object.class.dynamodb_config.table_name }))
  end

end
