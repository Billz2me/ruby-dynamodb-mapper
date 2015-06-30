module Mapymo::Persistence

  # Mapymo::Persistence::Error
  class Error < Mapymo::Error; end

  # Mapymo::Persistence::RecordNotSaved
  class RecordNotSaved < Error; end

  # Public: Save this instance of Mapymo::Object.
  #
  # save_options - The options for Mapymo::Mapper#save
  #
  # Returns true/false if the record saves.
  def save(save_options = {})
    if self.hash_key.nil? || (self.class.dynamodb_config.range_key && self.range_key.nil?)
      raise ArgumentError.new("Can't save without key attributes set - #{ self.dynamodb_key }")
    end
    begin
      save!(save_options)
    rescue RecordNotSaved => e
      false
    end
  end

  # Public: Save and raise Mapymo::Persistence::RecordNotSaved if the call fails.
  # See #save.
  def save!(save_options = {})
    begin
      self.class.dynamodb_config.mapper.save(self, save_options)
    rescue Mapymo::Error => e
      raise RecordNotSaved.new(e)
    end
  end

end
