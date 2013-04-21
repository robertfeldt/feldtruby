require 'json'

# Include this for objects that implement to_json by mapping key values to a 
# hash and then converting it to json.
module ToJsonImplementedViaDataHash
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data' => data_to_json_hash
    }.to_json(*a)
  end

  def data_to_json_hash
    {} # You should override this and save the key data of your objects...
  end
end