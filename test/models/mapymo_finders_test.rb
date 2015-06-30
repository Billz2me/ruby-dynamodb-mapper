class MapymoFindersTest < ActiveSupport::TestCase

  def setup
    @client = mock
    @mapper = Mapymo::Mapper.new(@client)
    MappedObject.dynamodb_config.mapper = @mapper
    OtherMappedObject.dynamodb_config.mapper = @mapper

    @test_hash_key = "test_hash_key"
    @test_range_key = "test_range_key"
  end

  test 'find should invoke @mapper#db_load correctly' do
    @mapper.expects(:db_load).with(MappedObject, @test_hash_key, nil, {}).once
    MappedObject.find(@test_hash_key)
  end

  test 'find should invoke @mapper#db_load correctly with consistent read and range key' do
    @mapper.expects(:db_load).with(OtherMappedObject, @test_hash_key, @test_range_key, {}).once
    OtherMappedObject.find(@test_hash_key, @test_range_key)
  end

  test 'find with options should invoke @mapper#db_load correctly' do
    @mapper.expects(:db_load).with(MappedObject, @test_hash_key, nil, { :some_option => "some_option" })
    MappedObject.find(@test_hash_key, nil, { :some_option => "some_option" })
  end

  test 'find should raise error if keys arent set' do
    @mapper.expects(:db_load).never
    assert_raises(ArgumentError) { MappedObject.find(nil) }
    assert_raises(ArgumentError) { OtherMappedObject.find(@test_hash_key, nil) }
  end

  test 'find should return nil if db_load is nil' do
    @mapper.stubs(:db_load).returns(nil)
    assert_nil MappedObject.find(@test_hash_key)
  end

  test 'test find! should raise RecordNotFound if the result of @mapper#db_load is nil' do
    @mapper.stubs(:db_load).returns(nil)
    assert_raises(Mapymo::Finders::RecordNotFound) { MappedObject.find!(@test_hash_key) }
  end

  test 'test find! should return the same result as find' do
    object = MappedObject.new(:id => @test_hash_key)
    @mapper.stubs(:db_load).returns(object)
    assert_equal MappedObject.find!(@test_hash_key), MappedObject.find(@test_hash_key)
  end

end

