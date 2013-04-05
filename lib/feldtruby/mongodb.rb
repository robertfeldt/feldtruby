require 'mongo'
require 'bson'


module FeldtRuby

def self.is_mongo_running?
  begin
    Mongo::MongoClient.new("localhost", 27017)
    return true
  rescue Exception => e
    return false
  end
end

end
