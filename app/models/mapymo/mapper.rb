class Mapymo::Mapper

  # Public: Mapymo::Mapper::Error.
  class Error < Mapymo::Error; end

  # Public: Constructor
  #
  # dynamo_db_client - The AWS dynamo db client.
  # config_options - Mapymo::Mapper config options.
  #
  # Returns a new Mapymo::Mapper.
  def initialize(dynamo_db_client = Aws::DynamoDB::Client.new, config_options = {})
    @dynamo_db_client = dynamo_db_client
    @config_options = config_options
  end

  # Public: Marshal a get item output into an object of type object_class.
  #
  # object_class - The class of the object to marshal into.
  # item - The item hash to marshal into an object.
  #
  # Returns an instance of object_class.
  def marshal_into_object(object_class, item)
    return nil if item.nil?
    item_attribute_hash = {}
    attribute_map = object_class.dynamodb_config.attribute_map
    attribute_map.each { |dynamo_attr, object_attr| item_attribute_hash[object_attr] = item[dynamo_attr] }
    begin
      object_class.new(item_attribute_hash)
    rescue NoMethodError => e
      raise Mapymo::Mapper::Error.new("Unable to marshal #{item} into #{object_class} using attribute map #{attribute_map}, #{e.message}")
    end
  end

  # Public: Marshal a list of objects.
  # See #marshal_into_object.
  def marshal_into_objects(object_class, items)
    items.map { |item| marshal_into_object(object_class, item) }
  end

  # Public: Reverse operation of marshal_into_object.
  #
  # object - The object to marshal into an item.
  #
  # Returns a dynamo db item hash.
  def marshal_into_item(object)
    item_hash = {}
    begin
      attribute_map = object.class.dynamodb_config.attribute_map
      attribute_map.each { |dynamo_attr, object_attr| item_hash[dynamo_attr] = object[dynamo_attr] }
    rescue NoMethodError => e
      raise Mapymo::Mapper::Error.new("Unable to marshal #{object.inspect} into item using attribute_map #{attribute_map}")
    end
    item_hash
  end

  # Public: Marshal a list of items.
  # See #marshal_into_item.
  def marshal_into_items(objects)
    objects.map { |object| marshal_into_item(object) }
  end

  # Public: Load object from DynamoDB and serialize into the item of object.
  #
  # hash_key - The hash key of the object.
  # range_key - (option) The range key of the object.
  # options - (optional) The same as options to Aws::DynamoDB::Client#get_item
  #
  def db_load(object_class, hash_key, range_key = nil, get_item_options = {})
    result = @dynamo_db_client.get_item(get_item_options.merge({ key: object_class.dynamodb_key(hash_key, range_key),
                                                                 table_name: object_class.dynamodb_config.table_name }))
    marshal_into_object(object_class, result.item)
  end

  # Public: Save the given object.
  #
  # hash_key - The object to save.
  # put_item_options - An options hash for Aws::DynamoDB::Client#put_item.
  #
  # Returns true/false if the record was saved.
  def save(object, put_item_options = {})
    @dynamo_db_client.put_item(put_item_options.merge({ item: marshal_into_item(object),
                                                        table_name: object.class.dynamodb_config.table_name }))
    return true
  end

  # Public: Batch load objects.
  #
  # list_of_objects - A list of objects with their key attributes set.
  #
  # Returns a hash of table names to the objects returned for that table.
  def batch_load(list_of_objects)
    table_name_classes = {}
    request_items = {}

    list_of_objects.each do |obj|
      table_name = obj.class.dynamodb_config.table_name
      table_name_classes[table_name] = obj.class
      request_items[table_name] ||= { keys: [] }
      request_items[table_name][:keys] << obj.dynamodb_key
    end

    result = @dynamo_db_client.batch_get_item(request_items: request_items)
    tablenames_to_objects = {}

    result.responses.each do |table_name, table_items|
      object_class = table_name_classes[table_name]
      tablenames_to_objects[table_name] = marshal_into_objects(object_class, table_items)
    end

    tablenames_to_objects
  end


end
