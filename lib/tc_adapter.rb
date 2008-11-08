require 'rubygems'
require 'dm-core'
require 'tokyocabinet'
require 'ostruct'
include TokyoCabinet
require 'ruby-debug'

module DataMapper
  module Adapters
    class TokyoCabinetAdapter < AbstractAdapter
      
      def create(resources)
        data_path = DataMapper.repository.adapter.uri[:data_path].to_s + "/"
        
        #Getting the latest id
        #TODO:Find out how to get last id using FDB, rather than BDB
        item = BDB::new
        item.open(data_path + "Item.bdb", BDB::OWRITER | BDB::OCREAT)
        cur = BDBCUR::new(item)
        cur.last
        item_id = cur.key.to_i + 1
    
        # Setting id
        resources.each do |resource|
          # >> resource.class.key(self.name)
          # => [#<Property:User:id>]
          key = resource.class.key(self.name)
          resource.instance_variable_set(
            key.first.instance_variable_name, item_id
          )
        end
        
        # Saving Item to DB
        record = OpenStruct.new
        record.id = item_id
        item.put(item_id, Marshal.dump(record))
        item.close        
      end

      def read_many(query)
        raise NotImplementedError
      end

      def read_one(query)
        raise NotImplementedError
      end

      def update(attributes, query)
        raise NotImplementedError
      end

      def delete(query)
        raise NotImplementedError
      end
    end # class AbstractAdapter
  end # module Adapters
end # module DataMapper


