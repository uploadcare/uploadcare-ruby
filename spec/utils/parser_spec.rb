require 'spec_helper'

describe Uploadcare::Parser do
  before :all do
    # https://ucarecdn.com/be4e24fb-2cad-476f-9417-ba95e3fefbf2~3/-/crop/123/-/fromat/png/
    @uuid = "be4e24fb-2cad-476f-9417-ba95e3fefbf2"
    @count = "12"
    @operations = "-/crop/123/-/fromat/png/"
  end

  it "should parse file uuid string" do
    string = "#{@uuid}"
    
    parsed = Uploadcare::Parser.parse(string)
    
    expect(parsed).to be_kind_of(Uploadcare::Parser::File)
    expect(parsed.uuid).to eq @uuid
    expect(parsed.count).to be_nil
    expect(parsed.operations).to be_kind_of(Array)
    expect(parsed.operations).to be_empty
  end

  it "should parse file cdn string without operations string" do
    string = "https://ucarecdn.com/#{@uuid}/"
    
    parsed = Uploadcare::Parser.parse(string)
    
    expect(parsed).to be_kind_of(Uploadcare::Parser::File)
    expect(parsed.uuid).to eq @uuid
    expect(parsed.count).to be_nil
    expect(parsed.operations).to be_kind_of(Array)
    expect(parsed.operations).to be_empty
  end

  it "should parse file cdn string with operations string" do
    string = "https://ucarecdn.com/#{@uuid}/#{@operations}"
    
    parsed = Uploadcare::Parser.parse(string)
    
    expect(parsed).to be_kind_of(Uploadcare::Parser::File)
    expect(parsed.uuid).to eq @uuid
    expect(parsed.count).to be_nil
    expect(parsed.operations).to be_kind_of(Array)
    expect(parsed.operations).not_to be_empty
  end

  it "should parse group uuid string" do
    string = "#{@uuid}~#{@count}"
    
    parsed = Uploadcare::Parser.parse(string)
    
    expect(parsed).to be_kind_of(Uploadcare::Parser::Group)
    expect(parsed.uuid).to eq "#{@uuid}~#{@count}"
    expect(parsed.count).not_to be_nil
    expect(parsed.count).to eq @count
    expect(parsed.operations).to be_kind_of(Array)
    expect(parsed.operations).to be_empty
  end

  it "should parse file cdn string without operations string" do
    string = "https://ucarecdn.com/#{@uuid}~#{@count}/"
    
    parsed = Uploadcare::Parser.parse(string)
    
    expect(parsed).to be_kind_of(Uploadcare::Parser::Group)
    expect(parsed.uuid).to eq "#{@uuid}~#{@count}"
    expect(parsed.count).not_to be_nil
    expect(parsed.count).to eq @count
    expect(parsed.operations).to be_kind_of(Array)
    expect(parsed.operations).to be_empty
  end

  it "should parse file cdn string with operations string" do
    string = "https://ucarecdn.com/#{@uuid}~#{@count}/#{@operations}"
    
    parsed = Uploadcare::Parser.parse(string)
    
    expect(parsed).to be_kind_of(Uploadcare::Parser::Group)
    expect(parsed.uuid).to eq "#{@uuid}~#{@count}"
    expect(parsed.count).not_to be_nil
    expect(parsed.count).to eq @count
    expect(parsed.operations).to be_kind_of(Array)
    expect(parsed.operations).not_to be_empty
  end  
end
