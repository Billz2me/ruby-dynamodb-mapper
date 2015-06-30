module Mapymo::Finders
  extend ActiveSupport::Concern

  # Mapymo::Finders::Error
  class Error < Mapymo::Error; end

  # Mapymo::Finders::RecordNotFound
  class RecordNotFound < Mapymo::Finders::Error; end

  class_methods do

    # Public: Find an item by a hash and (optional) range key.
    #
    # hash_key - The hash key to check the table for.
    # range_key - The range key to check the table for.
    # consistent_read - true/false for consistent read. Default to false.
    #
    # Returns an object of this class if found, otherwise nil.
    def find(hash_key, range_key = nil, options = {})
      if hash_key.nil? ||(self.dynamodb_config.range_key.present? && range_key.nil?)
        raise ArgumentError.new("Invalid key attributes provided to find #{self.name}")
      end
      self.dynamodb_config.mapper.db_load(self, hash_key, range_key, options)
    end

    # Public: Does a consistent read and raises Mapymo::Finders::RecordNotFound if the record does not exist.
    # See #find.
    def find!(hash_key, range_key = nil, options = {})
      result = find(hash_key, range_key, options)
      raise RecordNotFound.new("#{self.name} with hash_key #{hash_key} and range_key #{range_key} was not found.") if result.nil?
      result
    end

  end # end class_methods

end
