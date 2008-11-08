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
        do_tokyo_cabinet do |item|
          cur = BDBCUR::new(item)
          cur.last
          item_id = cur.key.to_i + 1
          
          resources.each do |resource|
            # >> resource.class.key(self.name)
            # => [#<Property:User:id>]
            key = resource.class.key(self.name)
            resource.instance_variable_set(
              key.first.instance_variable_name, item_id
            )
          end
        
          # Saving Item to DB
          attributes = resources.first.attributes
          attributes[:id] = item_id
          
          record = OpenStruct.new(attributes)
          item.put(item_id, Marshal.dump(record))
        end
        # item.close        
      end

      def read_many(query)
        raise NotImplementedError
      end

      def read_one(query)
        #DataMapper::Query 
        #query
        # => #<DataMapper::Query @repository=:default @model=User @fields=[#<Property:User:id>,
        # <Property:User:name>, #<Property:User:age>] @links=[] 
        # @conditions=[[:eql, #<Property:User:id>, 1]] 
        # @order=[#<DataMapper::Query::Direction #<Property:User:id> asc>] 
        # @limit=1 @offset=0 @reload=false @unique=fa
        item_id = query.conditions.first.last

        data = do_tokyo_cabinet do |item|
          # OpenStruct#marshal_dump convets OpenStruct into a hash
          Marshal.load(item.get(item_id)).marshal_dump
        end

        data = query.fields.map do |property|
          data[property.field.to_sym]
        end
        
        query.model.load(data,query)
      end

      def update(attributes, query)
        raise NotImplementedError
      end

      def delete(query)
        raise NotImplementedError
      end
      
    private
      def do_tokyo_cabinet(&block)
        data_path = DataMapper.repository.adapter.uri[:data_path].to_s + "/"
        
        #Getting the latest id
        #TODO:Find out how to get last id using FDB, rather than BDB
        item = BDB::new
        item.open(data_path + "Item.bdb", BDB::OWRITER | BDB::OCREAT)
        
        result = yield (item)
        
        item.close        

        result
      end
    end # class AbstractAdapter
  end # module Adapters
end # module DataMapper


