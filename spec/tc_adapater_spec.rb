require 'pathname'
require Pathname(__FILE__).dirname.expand_path + 'spec_helper'

describe DataMapper::Adapters::TokyoCabinetAdapter do
  before(:each) do
    db_files = Dir.glob(DataMapper.repository.adapter.uri[:data_path].to_s + "/*.*db")
    FileUtils.rm(db_files)
    @user = User.create(:name => 'tom')
  end
  # before(:each) do
  #   pending
  # end
  
  describe "Repository" do
    it "should return adapter name" do
      DataMapper.repository.adapter.uri[:adapter].should == 'tokyo_cabinet'
    end
    
    it "should return data path" do
      DataMapper.repository.adapter.uri[:data_path].should == Pathname(__FILE__).dirname.parent.expand_path + 'data'
    end
  end
    
  describe "Basic CRUD" do
    describe "create" do
      it "should assign id and attributes" do
        user = User.create
        user.should be_an_instance_of(User)
        user.id.should_not == nil
      end
      
      it "should increment id" do
        first_user = User.create
        second_user = User.create
        first_user.id.should == second_user.id - 1
      end
    end

    it "should get an item" do
      User.get(@user.id).should == @user
    end

    it "should raise error if item does not exist" do
      pending
      User.get(0).should == @user
      lambda {User.get(@user.id)}.should_raise DataMapper::ObjectNotFoundError
    end

    it "should update an item" do
      pending
      @user.name = 'peter'
      @user.save
      User.get(@user.id).name.should == @user.name
    end
    it "should destroy an item" do
      pending
      @user.destroy
      lambda {User.get(@user.id)}.should_raise DataMapp::ObjectNotFound
    end
  end

  describe 'Finder' do
    before(:each) do
      User.create(:name => 'tom')
      User.create(:name => 'peter')
    end
    it 'should get one record' do
      pending
      User.first.should have(1).user
    end
    it 'should get all records' do
      pending
      User.all.should have.at_least(2).users
    end
  end

  describe "Matcher" do
    it 'should get records by eql matcher' 
    it 'should get records by not matcher'
    it 'should get records by gt matcher'
    it 'should get records by gte matcher'
    it 'should get records by lt matcher'
    it 'should get records by lte matcher'
    it 'should get records with multiple matchers'
  end

  describe "DataType" do
    it "should order numeric"
  end
   
  describe 'associations' do
   before(:each) do
     pending
     @user = User.create(:name => 'tom')
     @post = Post.create(:title => 'Good morning')
     @user.posts << @post
   end
   it 'should work with belongs_to associations' do 
     pending
     @user.posts.should be_include(@post)
   end
    
   it 'should work with has n associations' do
     pending
     @post.user.should == @user
   end
  end
end