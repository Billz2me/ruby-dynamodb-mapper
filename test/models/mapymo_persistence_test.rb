class MapymoPersistenceTest < ActiveSupport::TestCase

  def setup
    @client = mock
    @mapper = Mapymo::Mapper.new(@client)
    MappedObject.dynamodb_config.mapper = @mapper
    OtherMappedObject.dynamodb_config.mapper = @mapper

    @saveable_object = MappedObject.new(:id => 'test')
    @saveable_other = OtherMappedObject.new(:my_key => 'test', :my_range => 'test')
  end

  test 'save with just hash key' do
    @mapper.expects(:save).with(@saveable_object, {}).once
    @saveable_object.save
  end

  test 'save with hash and range' do
    @mapper.expects(:save).with(@saveable_other, {}).once
    @saveable_other.save
  end

  test 'save should correctly invoke @mapper#save with options' do
    options = { :some_option => "my option" }
    @mapper.expects(:save).with(@saveable_object, options).once
    @saveable_object.save(options)
  end

  test 'should raise ArgumentError if key attributes arent set' do
    assert_raises(ArgumentError) { MappedObject.new.save }
    assert_raises(ArgumentError) { OtherMappedObject.new(:my_key => "hash_key").save }
  end

  test 'should raise Mapymo::Persistence::RecordNotSaved if mapper raises a Mapymo::Error' do
    @mapper.stubs(:save).raises(Mapymo::Error.new("boom"))
    assert_raises(Mapymo::Persistence::RecordNotSaved) { @saveable_object.save! }
  end

end
