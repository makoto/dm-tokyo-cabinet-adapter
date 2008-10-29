require 'rubygems'

require 'pathname'
require Pathname(__FILE__).dirname.parent.expand_path + 'lib/tc_adapter'

DataMapper.setup(:default, {
  :adapter => 'tokyo_cabinet'
})

class Post
  include DataMapper::Resource
  
  property :id,         String, :key => true
  property :title,      String
  
  belongs_to :user
end

class User
  include DataMapper::Resource
  
  property :id,   String, :key => true
  property :name, String
  property :age,  Integer
  
  has n, :posts
end