class Mapymo::Config

  # Public: Mapymo:::Config::Error.
  class Error < Mapymo::Error; end

  attr_accessor :table_name, :hash_key, :range_key, :attribute_map, :mapper

  # Public: Constructor.
  #
  # Example: The following produce identical configurations:
  #
  #   Mapymo::Config.new(MyObject) do |config|
  #     config.hash_key = "myHashKey"
  #   end
  #
  #   Mapymo::Config.new(MyObject, { :hash_key => "myHashKey" })
  #
  # Returns a new instance of Mapymo::Config.
  def initialize(object_class, options = {}, &block)
    if block_given?
      yield(self)
    else
      self.table_name = options[:table_name]
      self.hash_key = options[:hash_key]
      self.range_key = options[:range_key]
      self.attribute_map = options[:attribute_map]
      self.mapper = options[:mapper]
    end
    set_defaults(object_class)
    validate!(object_class)
  end

  private

  # Internal: Set default values for this config if not already set.
  def set_defaults(object_class)
    self.table_name ||= object_class.name.pluralize
  end

  # Internal: Validate that this config is valid for the provided object class.
  #
  # object_class - The object class to validate this config for.
  def validate!(object_class)
    raise Error.new('hash_key is required') if self.hash_key.blank?
    raise Error.new('attribute_map is required') unless self.attribute_map.present?
    raise Error.new('table_name is required') if self.table_name.blank?

    attribute_map.each do |dynamodb_attr, object_attr|
      unless object_class.method_defined?(object_attr) && object_class.method_defined?("#{object_attr}=")
        raise Error.new("Expected attr_accessor methods for ##{object_attr} in order to map DynamoDB attribute #{dynamodb_attr}")
      end
    end
  end

end
