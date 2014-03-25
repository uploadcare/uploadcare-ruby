require 'spec_helper'

describe Uploadcare::Parser do
  before :all do
    # http://www.ucarecdn.com/be4e24fb-2cad-476f-9417-ba95e3fefbf2~3/-/crop/123/-/fromat/png/
    @uuid = "be4e24fb-2cad-476f-9417-ba95e3fefbf2"
    @count = "12"
    @operations = "-/crop/123/-/fromat/png/"
  end

  it "should parse file uuid string" do
    string = "#{@uuid}"
    
    parsed = Uploadcare::Parser.parse(string)
    
    parsed.should be_kind_of(Uploadcare::Parser::File)
    parsed.uuid.should == @uuid
    parsed.count.should be_nil
    parsed.operations.should be_kind_of(Array)
    parsed.operations.should be_empty
  end

  it "should parse file cdn string without operations string" do
    string = "http://www.ucarecdn.com/#{@uuid}/"
    
    parsed = Uploadcare::Parser.parse(string)
    
    parsed.should be_kind_of(Uploadcare::Parser::File)
    parsed.uuid.should == @uuid
    parsed.count.should be_nil
    parsed.operations.should be_kind_of(Array)
    parsed.operations.should be_empty
  end

  it "should parse file cdn string with operations string" do
    string = "http://www.ucarecdn.com/#{@uuid}/#{@operations}"
    
    parsed = Uploadcare::Parser.parse(string)
    
    parsed.should be_kind_of(Uploadcare::Parser::File)
    parsed.uuid.should == @uuid
    parsed.count.should be_nil
    parsed.operations.should be_kind_of(Array)
    parsed.operations.should_not be_empty
  end

  it "should parse group uuid string" do
    string = "#{@uuid}~#{@count}"
    
    parsed = Uploadcare::Parser.parse(string)
    
    parsed.should be_kind_of(Uploadcare::Parser::Group)
    parsed.uuid.should == "#{@uuid}~#{@count}"
    parsed.count.should_not be_nil
    parsed.count.should == @count
    parsed.operations.should be_kind_of(Array)
    parsed.operations.should be_empty
  end

  it "should parse file cdn string without operations string" do
    string = "http://www.ucarecdn.com/#{@uuid}~#{@count}/"
    
    parsed = Uploadcare::Parser.parse(string)
    
    parsed.should be_kind_of(Uploadcare::Parser::Group)
    parsed.uuid.should == "#{@uuid}~#{@count}"
    parsed.count.should_not be_nil
    parsed.count.should == @count
    parsed.operations.should be_kind_of(Array)
    parsed.operations.should be_empty
  end

  it "should parse file cdn string with operations string" do
    string = "http://www.ucarecdn.com/#{@uuid}~#{@count}/#{@operations}"
    
    parsed = Uploadcare::Parser.parse(string)
    
    parsed.should be_kind_of(Uploadcare::Parser::Group)
    parsed.uuid.should == "#{@uuid}~#{@count}"
    parsed.count.should_not be_nil
    parsed.count.should == @count
    parsed.operations.should be_kind_of(Array)
    parsed.operations.should_not be_empty
  end  


end