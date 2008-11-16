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

    describe "update" do
      before(:each) do
        @user.name = 'peter'
        @user.age = 22

        @user.save
      end
      it "should update an item" do
        User.get(@user.id) == @user
      end

      it "should reflect index" do
        User.first(:name => @user.name).should == @user
      end
    end

    describe "destroy" do
      before(:each) do
        @user.destroy
      end
      it "should destroy an item" do
        lambda{User.get!(@user.id)}.should raise_error(DataMapper::ObjectNotFoundError)
      end
      it "should reflect index" do
        User.first(:name => @user.name).should == nil
        User.all(:name => @user.name).should == []
      end
    end
  end

  describe 'Finder' do
    describe "when no data" do
      it "first should return nil" do
        User.first(:name => 'someone').should == nil
      end
      
      it "all should return []" do
        User.all(:name => 'someone').should == []
      end
    end
    
    describe "when data" do
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
        it "should return a record for string when non matching value comes first" do
          pending()
          User.first(:name.not => 'tom').should == @peter
        end
        
        it "should return a record for string when matching value comes first" do
          pending()
          User.first(:name.not => 'peter').should == @tom
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
      before(:each) do
        @tom = User.create(:name => 'tom', :age => 2)
        @peter = User.create(:name => 'peter', :age => 3)
        @mark = User.create(:name => 'mark', :age => 5)
        @andy = User.create(:name => 'andy', :age => 5)
      end
      it 'should get records by eql matcher' do
        User.all(:age => 5).should == [@mark, @andy]
      end
      it 'should get records by not matcher'
      it 'should get records by gt matcher'
      it 'should get records by gte matcher'
      it 'should get records by lt matcher'
      it 'should get records by lte matcher'
      it 'should get records with multiple matchers'
    end
  end

  describe "DataType" do
    before(:each) do
      @dave = User.create(:name => 'dave', :age => 5)
      @charles = User.create(:name => 'charles', :age => 15)
      @bob = User.create(:name => 'bob', :age => 3)
      @andy = User.create(:name => 'andy', :age => 4)
    end

    describe "sorting" do
      # Tokyo Cabinet itself does not provide sorting, so done at ruby level.
      it "should order by alphabet asc" do
        User.all(:order => [:name]).should == [@andy, @bob, @charles, @dave]
      end

      it "should order by alphabet desc" do
        User.all(:order => [:name.desc]).should == [@andy, @bob, @charles, @dave].reverse
      end

      it "should order by numeric asc" do
        User.all(:order => [:age]).should == [@bob, @andy, @dave, @charles]
      end

      it "should order by numeric desc" do
        User.all(:order => [:age.desc]).should == [@bob, @andy, @dave, @charles].reverse
      end
    end
  end
  
  describe 'associations' do
    before(:each) do
      @user = User.create(:name => 'tom')
      @post = Post.create(:title => 'Good morning', :user => @user)
    end
  
    describe "Adding association" do
     it 'should work with belongs_to associations' do 
       User.get(@user.id).posts.should include(@post)
     end

     it 'should work with has n associations' do
       Post.get(@post.id).user.should == @user
     end
    end
    describe "Appending association" do
      before(:each) do
        @post2 = Post.create(:title => 'Good morning', :user => @user)
        @user.posts << @post2
      end
      it 'should work with belongs_to associations' do 
        User.get(@user.id).posts.should == [@post, @post2]
      end

      it 'should work with has n associations' do
        Post.get(@post.id).user.should == @user
        Post.get(@post2.id).user.should == @user
      end
    end
  end
end