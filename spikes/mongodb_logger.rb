$: << "../lib"
require 'feldtruby/mongodb_logger'

#l = FeldtRuby::MongoDBLogger.new
adbs = FeldtRuby::AllMongoDBLoggers.new "localhost", 27017

#adbs.delete_logger_dbs false
#exit -1

require 'pp'

#pp adbs.all_log_infos

mc = Mongo::MongoClient.new "localhost", 27017

mc.database_names.each do |dbname|

  db = mc.db(dbname)

  cnames = db.collection_names

  puts "db #{dbname} has #{cnames.length} collections: #{cnames.inspect}"

  cnames.each do |cname|

    next if cname == "system.indexes"

    c = db[cname]

    puts "#{dbname}/#{cname}:"
    pp c.find.to_a

  end

end

#pp l.mongo_client.database_names



#adbs.delete_all_logger_dbs_except_last_one

#pp adbs.all_log_infos

#l.log_value :a, 1

#pp l.mongo_client.database_names