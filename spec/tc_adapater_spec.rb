require 'pathname'
require Pathname(__FILE__).dirname.expand_path + 'spec_helper'

describe DataMapper::Adapters::TokyoCabinetAdapter do
  describe "Basic CRUD" do
    it "should create an item" 
    it "should update an item"
    it "should destroy an item"
    it "should get an item"
  end

  describe 'Finder' do
    it 'should get one record' 
    it 'should get all records' 
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
   it 'should work with belongs_to associations'
   it 'should work with has n associations'
  end
end