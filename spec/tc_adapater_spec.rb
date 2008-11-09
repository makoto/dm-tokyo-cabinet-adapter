require 'pathname'
require Pathname(__FILE__).dirname.expand_path + 'spec_helper'

describe DataMapper::Adapters::TokyoCabinetAdapter do
  before(:each) do
    db_files = Dir.glob(DataMapper.repository.adapter.uri[:data_path].to_s + "/*.*db")
    FileUtils.rm(db_files)
  end
  
  describe "Repository" do
    it "should return adapter name" do
      DataMapper.repository.adapter.uri[:adapter].should == 'tokyo_cabinet'
    end
    
    it "should return data path" do
      DataMapper.repository.adapter.uri[:data_path].should == Pathname(__FILE__).dirname.parent.expand_path + 'data'
    end
  end
    
  describe "CRUD" do
    before(:each) do
      @user = User.create(:name => 'tom')
    end
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

    describe "get" do
      it "should get an item" do
        User.get(@user.id).should == @user
      end

      it "should raise error if item does not exist" do
        non_existance_number = 100
        lambda{User.get!(non_existance_number)}.should raise_error(DataMapper::ObjectNotFoundError)
      end
    end

    it "should update an item" do
      @user.name = 'peter'
      @user.age = 22
      
      @user.save
      user = User.get(@user.id)
      user.name.should == @user.name
      user.age.should == @user.age
    end
    it "should destroy an item" do
      @user.destroy
      lambda{User.get!(@user.id)}.should raise_error(DataMapper::ObjectNotFoundError)
    end
  end

  describe 'Finder' do
    before(:each) do
      @tom = User.create(:name => 'tom')
      @peter = User.create(:name => 'peter')
      @post = Post.create
    end

    it 'should get one record per model' do
      User.first.should == @tom
      Post.first.should == @post
    end

    it 'should return collection of all records per model' do
      Post.all.should have(1).post
      User.all.should have(2).users
    end
    
  end

  describe "Matcher" do
    describe "first" do
      describe "eql" do
        before(:each) do
          @tom = User.create(:name => 'tom', :age => 32)
          @peter = User.create(:name => 'peter', :age => 32)
        end
        
        it "should return a record " do
          User.first(:name => 'tom').should == @tom
        end
        it "should return first record when searched by an attribute which allows duplicate entry" do
          User.first(:age => 32).should == @tom        
        end
      end

      describe "not" do
        before(:each) do
          @tom = User.create(:name => 'tom', :age => 2)
          @peter = User.create(:name => 'peter', :age => 3)
          @mark = User.create(:name => 'mark', :age => 5)
        end
        it "should return a record for string" do
          User.first(:name.not => 'tom').should == @peter
        end
        it "should return a record for numeric" do
          pending
          User.first(:age.not => 2).should == @peter
        end
        
      end
      it 'should get a record by not matcher'
      it 'should get a record by gt matcher'
      it 'should get a record by gte matcher'
      it 'should get a record by lt matcher'
      it 'should get a record by lte matcher'
      it 'should get a record with multiple matchers'
    end
    describe "all" do
      it 'should get records by eql matcher'
      it 'should get records by not matcher'
      it 'should get records by gt matcher'
      it 'should get records by gte matcher'
      it 'should get records by lt matcher'
      it 'should get records by lte matcher'
      it 'should get records with multiple matchers'
    end
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