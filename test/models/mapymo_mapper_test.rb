require 'test_helper'
require 'ostruct'

class MapymoMapperTest < ActiveSupport::TestCase

  def setup
    @client = mock
    @mapper = Mapymo::Mapper.new(@client)

    @test_hash_key = "test_hash_key"
    @test_attr = "test_attr"
    @test_range_key = "test_range_key"

    @mapped_object = MappedObject.new(id: @test_hash_key, test_attr: @test_attr)
    @mapped_object_item = { MappedObject::HASH_KEY  => @test_hash_key,
                            MappedObject::TEST_ATTR => @test_attr }

    @other_object = OtherMappedObject.new(my_key: @test_hash_key, my_attr: @test_attr, my_range: @test_range_key)
    @other_item = { OtherMappedObject::HASH_KEY  => @test_hash_key,
                    OtherMappedObject::TEST_ATTR => @test_attr,
                    OtherMappedObject::RANGE_KEY => @test_range_key}
  end

  ##########################################################################
  #                              marshal_into_object                       #
  ##########################################################################

  test 'marshal_into_object should return nil if item is nil' do
    assert_nil @mapper.marshal_into_object(MappedObject, nil)
  end

  test 'marshal_into_object should return correctly marshalled object' do
    object = @mapper.marshal_into_object(MappedObject, @mapped_object_item)
    assert_kind_of MappedObject, object
    assert_equal @test_hash_key, object.id
    assert_equal @test_attr, object.test_attr

    object = @mapper.marshal_into_object(OtherMappedObject, @other_object)
    assert_kind_of OtherMappedObject, object
    assert_equal @test_hash_key, object.my_key
    assert_equal @test_attr, object.my_attr
  end

  test 'marshal_into_object should be the inverse of marshal_into_item' do
    marshalled = @mapper.marshal_into_object(MappedObject, @mapper.marshal_into_item(@mapped_object))
    assert_equal @mapped_object.id, marshalled.id
    assert_equal @mapped_object.test_attr, marshalled.test_attr
  end

  ##########################################################################
  #                              marshal_into_objects                      #
  ##########################################################################

  test 'marshal_into_objects should marshal a list of the same type of items' do
    just_hash = { MappedObject::HASH_KEY => @test_hash_key }
    just_test_attr = { MappedObject::TEST_ATTR => @test_attr }

    result = @mapper.marshal_into_objects(MappedObject, [@mapped_object_item, just_hash, just_test_attr])

    assert_kind_of Array, result
    assert_equal 3, result.size
    assert result.all? { |res| res.is_a?(MappedObject) }

    # @test_item
    assert_equal @test_hash_key, result.first.id
    assert_equal @test_attr, result.first.test_attr

    # just_hash
    assert_equal @test_hash_key, result.second.id
    assert_nil result.second.test_attr

    # just_test_attr
    assert_nil result.third.id
    assert_equal @test_attr, result.third.test_attr
  end

  ##########################################################################
  #                              marshal_into_item                         #
  ##########################################################################

  test 'marshal_into_item should correctly marshall into dynamo item hash' do
    assert_equal @mapped_object_item, @mapper.marshal_into_item(@mapped_object)
    assert_equal @other_item, @mapper.marshal_into_item(@other_object)
  end

  test 'marshal_into_item should be the inverse of marshal_into_object' do
    assert_equal @mapped_object_item, @mapper.marshal_into_item(@mapper.marshal_into_object(MappedObject, @mapped_object_item))
  end

  test 'should raise error if trying to marshal nil' do
    assert_raises(Mapymo::Mapper::Error) { @mapper.marshal_into_item(nil) }
  end

  ##########################################################################
  #                              marshal_into_items                        #
  ##########################################################################

  test 'marshal_into_items should returned the individually marshalled items' do
    result = @mapper.marshal_into_items([@mapped_object, @other_object])
    assert_kind_of Array, result
    assert_equal 2, result.size

    assert_equal @mapper.marshal_into_item(@mapped_object), result.first
    assert_equal @mapper.marshal_into_item(@other_object), result.second
  end

  ##########################################################################
  #                                   load                                 #
  ##########################################################################

  test 'load should correctly call @client#get_item with hash key' do
    response = OpenStruct.new(:item => nil)

    @client.expects(:get_item).with({ :key        => { MappedObject::HASH_KEY => @test_hash_key },
                                      :table_name => MappedObject.dynamodb_config.table_name}).once.returns(response)
    @mapper.expects(:marshal_into_object).with(MappedObject, response.item).once

    @mapper.load(MappedObject, @test_hash_key)
  end

  test 'load should merge in the options to the @client#get_item call' do
    @client.expects(:get_item).with({ :key         => { MappedObject::HASH_KEY => @test_hash_key },
                                      :table_name  => MappedObject.dynamodb_config.table_name,
                                      :some_option => "my option" }).once.returns(OpenStruct.new)

    @mapper.load(MappedObject, @test_hash_key, nil, { :some_option => "my option" })
  end

  test 'load should correctly call @client#get_item with hash and range key' do
    response = OpenStruct.new(:item => nil)

    @client.expects(:get_item).with({ :key => { OtherMappedObject::HASH_KEY  => @test_hash_key,
                                                OtherMappedObject::RANGE_KEY => @test_range_key },
                                      :table_name => OtherMappedObject.dynamodb_config.table_name}).once.returns(response)
    @mapper.expects(:marshal_into_object).with(OtherMappedObject, response.item).once

    @mapper.load(OtherMappedObject, @test_hash_key, @test_range_key)
  end

  test 'load correctly marshals the response' do
    response = OpenStruct.new(:item => @mapper.marshal_into_item(@mapped_object))
    @client.expects(:get_item).once.returns(response)
    result = @mapper.load(MappedObject, 'test')
    assert_kind_of MappedObject, result
    assert_equal @test_hash_key, result.id
    assert_equal @test_attr, result.test_attr
  end

  ##########################################################################
  #                                   save                                 #
  ##########################################################################

  test 'save should correctly call @client#put_item' do
    @client.expects(:put_item).once.with({ item: @mapper.marshal_into_item(@mapped_object),
                                           table_name: MappedObject.dynamodb_config.table_name })

    @mapper.save(@mapped_object)
  end

  test 'save should merge in options' do
    @client.expects(:put_item).once.with({ :item        => @mapper.marshal_into_item(@mapped_object),
                                           :table_name  => MappedObject.dynamodb_config.table_name,
                                           :some_option => "my option" }).once

    @mapper.save(@mapped_object, { :some_option => "my option" })
  end

end
