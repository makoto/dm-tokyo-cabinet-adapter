require 'rubygems'
require 'dm-core'
require 'tokyocabinet'
include TokyoCabinet

module DataMapper
  module Adapters
    class TokyoCabinetAdapter < AbstractAdapter
      
      def create(resources)
        resource = resources[0]
        attributes = resource.attributes
        
        item_id = access_data(resource.model) do |item|
          #Getting the latest id
          #TODO:Find out how to get last id using FDB, rather than BDB
          cur = BDBCUR::new(item)
          cur.last
          attributes[:id] = cur.key.to_i + 1
          
          item.put(attributes[:id], Marshal.dump(attributes))
          attributes[:id]
        end

        resource.instance_variable_set(:@id, item_id)
        
        add_index(attributes, resource, item_id)
        
        # Seems required to return 1 to update @new_record instance variable at DataMapper::Resource.
        # Not quite sure how it works.
        1
      end

      def read_many(query)
        results = parse_query(query)

        if results
          results = results.sort_by do |result|
            result[query.order.first.property.name] if result
          end
          results = results.reverse if query.order.first.direction == :desc
        end

        if results # to handle results == nil
          Collection.new(query) do |collection|
            results.each do |result|
              data = map_into_query_field(query, result)
              if data # to handle results == [nil]
                collection.load(data)
              end
            end
          end
        else
          []
        end
      end

      def read_one(query)
        results = parse_query(query)
        data = (results.class == Array ? results.first : results)

        if data
          data = map_into_query_field(query, data)
          query.model.load(data, query)
        end
      end

      def update(attributes, query)
        item_id = get_id(query)
        
        old_attributes = get_items_from_id(query, item_id)
        delete_index(old_attributes, query, item_id)
        
        # Converting {#<Property:User:name>=>"peter", #<Property:User:age>=>22} to {:age=>22, :name=>"peter"}
        new_attributes = attributes.inject({}){|total,current|  total[current[0].name] = current[1]; total}
        add_index(new_attributes, query, item_id)
        
        access_data(query.model) do |item|
          raw_data = item.get(item_id)
          if raw_data
            record = Marshal.load(raw_data)

            attributes.each do |key, value|
              record[key.name.to_sym] = value
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
        attributes = get_items_from_id(query, item_id)
        
        delete_index(attributes, query, item_id)
        
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
      
      def get_items_from_id(query, values)
        values_in_array = (values.class == Array ? values : [values])
        result = values_in_array.map do |value|
          access_data(query.model) do |item|
            raw_data = item.get(value)
            if raw_data
              Marshal.load(raw_data)
            end
          end
        end
        values.class == Array ? result : result.first
      end
      
      def parse_query(query)
        results = []
        
        unless query.conditions.empty?
          operator, property, value = query.conditions.first
          
          if property.name == :id # Model.get
            results = get_items_from_id(query, value)
          else # Model.first w argument
            case operator
            when :eql
            then
              item_ids = access_data(query.model, property.name) do |item|
                value = value.first if value.class == Array                
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
        results
      end
      
      def map_into_query_field(query, data)
        if data
          query.fields.map do |property|
            data[property.field.to_sym]
          end
        end
      end

      def delete_index(attributes, query, item_id)
        # Don't need id attribute and attribut with no data.
        attributes.reject{|k,v| k == :id || v == nil}.each do | k, v|
          access_data(query.model, k) do |item|
            items = item.getlist(v)
            items = items - [item_id]
            item.out(v)
            if items.size > 0
              item.putlist(v, items)
            end
          end
        end
      end
      
      def add_index(attributes, query, item_id)
        attributes.each do |key, value|
          # Creating index for each attributes except id
          unless key == :id
            access_data(query.model, key) do |item|
              item.putlist(value, [item_id])
            end
          end
        end
      end
      
    end # class AbstractAdapter
  end # module Adapters
end # module DataMapper


