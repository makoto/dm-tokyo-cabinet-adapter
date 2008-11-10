require 'rubygems'
require 'dm-core'
require 'tokyocabinet'
include TokyoCabinet
require 'ruby-debug'

module DataMapper
  module Adapters
    class TokyoCabinetAdapter < AbstractAdapter
      
      def create(resources)
        resource = resources[0]
        attributes = resource.attributes
        
        item_id = access_data(resources.first.model) do |item|
          #Getting the latest id
          #TODO:Find out how to get last id using FDB, rather than BDB
          cur = BDBCUR::new(item)
          cur.last
          attributes[:id] = cur.key.to_i + 1
          
          item.put(attributes[:id], Marshal.dump(attributes))
          attributes[:id]
        end

        resource.instance_variable_set(:@id, item_id)
        
        # Creating index for each attributes except id
        attributes.each do |key, value|
          unless key == :id
            access_data(resource.class, key) do |item|
              item.putlist(value, [item_id])
            end
          end
        end
        
        # Seems required to return 1 to update @new_record instance variable at DataMapper::Resource.
        # Not quite sure how it works.
        1
      end

      def read_many(query)
        results = []
        
        unless query.conditions.empty?
          operator, property, value = query.conditions.first
          
          if property.name == :id # Model.get
            results = [get_item_from_id(query, value)]
          else # Model.first w argument
            case operator
            when :eql
            then
              item_ids = access_data(query.model, property.name) do |item|
                item.getlist(value)
              end
            when :not # TODO: Think about better way to extract, as this is going through data one by one
            then  NotImplementedError{"The below code is not working as order is not always correct"}
            else
              raise NotImplementedError("#{operator} is not implmented yet")
            end
            results = get_items_from_id(query, item_ids)
          end
        else # Model.all w/o argument
          access_data(query.model) do |item|
            #Getting the first id
            #TODO:Find out how to get first id using FDB, rather than BDB
            raw_data = BDBCUR::new(item)
            if raw_data.first
              while key = raw_data.key
                results << Marshal.load(raw_data.val)
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
        results = []
        
        unless query.conditions.empty?
          operator, property, value = query.conditions.first
           
          if property.name == :id # Model.get
            results = [get_item_from_id(query, value)]
          else # Model.first w argument
            case operator
            when :eql
            then
              item_id = access_data(query.model, property.name) do |item|
                item.get(value)
              end
            when :not # TODO: Think about better way to extract, as this is going through data one by one
            then  NotImplementedError{"The below code is not working as order is not always correct"}
            else
              raise NotImplementedError("#{operator} is not implmented yet")
            end
            results = [get_item_from_id(query, item_id)]
          end
        else # Model.first w/o argument
          data = access_data(query.model) do |item|
            raw_data = BDBCUR::new(item)
            if raw_data.first
              while key = raw_data.key
                results << Marshal.load(raw_data.val)
                raw_data.next
              end
            end
          end
        end
        
        data = results.first unless results.size == 0

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
              record[key.name.to_sym] = value
              # record.send("#{key.name}=", value)
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
        result = get_items_from_id(query, value)
        # access_data(query.model) do |item|
        #   raw_data = item.get(value)
        #   if raw_data
        #     Marshal.load(raw_data)
        #   end
        # end
        # p "get_item_from_id: #{result.inspect}"
      end
      
      # TODO: Refactor to consolidate with get_item_from_id method
      def get_items_from_id(query, values)

        result = values.to_a.map do |value|
          access_data(query.model) do |item|
            raw_data = item.get(value)
            if raw_data
              Marshal.load(raw_data)
            end
          end
        end
        result = result.first unless values.class == Array
        result
      end
      
    end # class AbstractAdapter
  end # module Adapters
end # module DataMapper


