require 'rubygems'

require 'pathname'
require Pathname(__FILE__).dirname.parent.expand_path + 'lib/tc_adapter'

DataMapper.setup(:default, {
  :adapter => 'tokyo_cabinet',
  :data_path => Pathname(__FILE__).dirname.parent.expand_path + 'data'
})

class Post
  include DataMapper::Resource

  property :id,         Serial
  property :title,      String
  
  belongs_to :user
end

class User
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String
  property :age,  Integer
  
  has n, :posts
end