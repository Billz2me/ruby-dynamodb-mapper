class MappedObject
  include Mapymo::Object

  attr_accessor :id, :test_attr

  HASH_KEY = "MyHashKey"
  TEST_ATTR = "MyTestAttr"

  configure_mapymo do |config|
    config.hash_key = HASH_KEY
    config.attribute_map = { HASH_KEY  => :id,
                             TEST_ATTR => :test_attr }
  end
end

class OtherMappedObject
  include Mapymo::Object

  attr_accessor :my_key, :my_range, :my_attr

  HASH_KEY = "MyHashKey"
  RANGE_KEY = "MyRangeKey"
  TEST_ATTR = "MyTestAttr"

  configure_mapymo do |config|
    config.hash_key = HASH_KEY
    config.range_key = RANGE_KEY
    config.attribute_map = { HASH_KEY  => :my_key,
                             TEST_ATTR => :my_attr,
                             RANGE_KEY => :my_range}
  end

end
