class Image
  include DynamoDB::ORM

  attr_accessor :image_id, :s3_link, :test

  configure_dynamodb do |config|
    config.hash_key = "ImageID"
    config.attribute_map = { "ImageID"  => :image_id,
                             "S3Link"   => :s3_link,
                             "teststttt" => :test }
  end

end
