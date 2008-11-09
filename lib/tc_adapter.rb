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
        item_id = access_data(resources.first.model) do |item|
          #Getting the latest id
          #TODO:Find out how to get last id using FDB, rather than BDB
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
          item_id
        end
        
        # Creating index for each attributes except id
        resources.first.attributes.each do |key, value|
          unless key == :id
            access_data(resources.first.class, key) do |item|
              item.putlist(value, [item_id])
            end
          end
        end
        
        # Seems required to return 1 to update @new_record instance variable at DataMapper::Resource.
        # Not quite sure how it works.
        1
      end

      def read_many(query)
        condition = get_id(query)
        results = []
        
        if condition # Model.all w argument
          raise NotImplementedError
        else # Model.all w/o argument
          access_data(query.model) do |item|
            #Getting the first id
            #TODO:Find out how to get first id using FDB, rather than BDB
            raw_data = BDBCUR::new(item)
            if raw_data.first
              while key = raw_data.key
                results << Marshal.load(raw_data.val).marshal_dump
                raw_data.next
              end
            end
          end
        end

        Collection.new(query) do |collection|
          results.each do |result|
            
            data = query.fields.map do |property|
              result[property.field.to_sym]
            end
            
            collection.load(data)
          end
        end
      end

      def read_one(query)
        unless query.conditions.empty?
          operator, property, value = query.conditions.first
           
          if property.name == :id # Model.get
            data = get_item_from_id(query, value)
          else # Model.first w argument
            item_id = access_data(query.model, property.name) do |item|
              item.get(value)
            end
            data = get_item_from_id(query, item_id)
          end
        else # Model.first w/o argument
          data = access_data(query.model) do |item|
            raw_data = BDBCUR::new(item)
            if raw_data.first
              Marshal.load(raw_data.val).marshal_dump
            end
          end
        end

        if data
          data = query.fields.map do |property|
            data[property.field.to_sym]
          end
          query.model.load(data,query)
        end
      end

      def update(attributes, query)
        item_id = get_id(query)
        access_data(query.model) do |item|
          raw_data = item.get(item_id)
          if raw_data
            record = Marshal.load(raw_data)

            attributes.each do |key, value|
              record.send("#{key.name}=", value)
            end

            item.put(item_id, Marshal.dump(record))              
          end
        end
        # Seems required to return 1 to update @new_record instance variable at DataMapper::Resource.
        # Not quite sure how it works.
        1
      end
      
      def delete(query)
        item_id = get_id(query)
        access_data(query.model) do |item|
          item.out(item_id)
        end
        # Seems required to return 1 to update @new_record instance variable at DataMapper::Resource.
        # Not quite sure how it works.
        1
      end
      
    private
      # Access Index file if property is given. If not, access data file
      def access_data(model, property = nil, &block)
        item = BDB::new
        attribute = property.to_s.capitalize if property
          
        item.open(data_path + "#{model}#{attribute}.bdb", BDB::OWRITER | BDB::OCREAT)
        
        result = yield(item)
        
        item.close        

        result
      end
      
      def data_path
        data_path = DataMapper.repository.adapter.uri[:data_path].to_s + "/"
      end
            
      def get_id(query)
        unless query.conditions.empty?
          query.conditions.first.last
        end
      end
      
      def get_item_from_id(query, value)
        access_data(query.model) do |item|
          raw_data = item.get(value)
          # OpenStruct#marshal_dump convets OpenStruct into a hash
          if raw_data
            Marshal.load(raw_data).marshal_dump
          end
        end
      end
    end # class AbstractAdapter
  end # module Adapters
end # module DataMapper


