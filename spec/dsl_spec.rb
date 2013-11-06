require 'spec_helper'
require 'uri'
require 'socket'


# simple test to cover all the api tricks
describe "Project" do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @project = @api.project
  end

  it "should get project for api instance" do
    @project.should be_an_instance_of(Uploadcare::Api::Project)
  end

  it "project should respond to all attr methods and return something" do
    @project.should respond_to :name
    @project.should respond_to :pub_key
    @project.should respond_to :autostore_enabled
    @project.should respond_to :collaborators
  end

  it "project collaborators should be an array" do
    @project.should respond_to :collaborators
    @project.collaborators.should be_an_instance_of(Array)
  end
end


describe "File uploading" do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
  end

  # it actually should return the file instance
  it "should be able to upload given file" do
    file = File.join(File.dirname(__FILE__), 'view.png')
    uuid = @api.upload_file file
    uuid.should match UUID_REGEX
  end

  # get the file instance instead
  it "should be able to upload given url with file" do
    url = "https://ucarecdn.com/3c99da1d-ef05-4d79-81d8-d4f208d98beb/"
    uuid = @api.upload_url(url)
    uuid.should match UUID_REGEX
  end
end


describe "File retrieving" do
  before :each do
    @api = Uploadcare::Api.new(CONFIG) 
    file = File.join(File.dirname(__FILE__), 'view.png')
    @uuid = @api.upload_file file 
  end

  it "should get file by uuid" do
    file = @api.file(@uuid)
    file.should be_an_instance_of Uploadcare::Api::File
  end
end


describe "File Lists" do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @files = @api.files
  end

  it "should get the files list" do
    @files.should be_an_instance_of Uploadcare::Api::FileList
  end

  it "file list should be avaliable though proxy" do
    @files.should respond_to :[]
    @files.should respond_to :to_a
  end

  it "file should be avaliable by index" do
    file = @files[0]
    file.should be_an_instance_of(Uploadcare::Api::File)
  end

  it "should be able to get an array of files" do
    files_array = @files.to_a
    files_array.should be_an_instance_of(Array)
  end

  it "file list should be paginated" do
    @files.page.should == 1
    @files.per_page.should > 0
    @files.total.should > 0
    @files.pages.should > 0
    expect { @api.files(@files.pages + 1) }.to raise_error(ArgumentError)
  end
end


describe "Single file api" do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @file = @api.file(@api.upload_file(File.join(File.dirname(__FILE__), 'view.png')))
  end

  it "should respond to all attr defined by api" do
    @file.should be_an_instance_of Uploadcare::Api::File
    @file.should respond_to :datetime_removed
    @file.should respond_to :datetime_stored
    @file.should respond_to :datetime_uploaded
    @file.datetime_uploaded.should be_an_instance_of(Time)
    @file.should respond_to :is_image
    @file.should respond_to :is_ready
    @file.should respond_to :is_public
    @file.should respond_to :mime_type
    @file.should respond_to :original_file_url
    @file.should respond_to :original_filename
    @file.should respond_to :size
    @file.should respond_to :url
    @file.should respond_to :uuid
  end

  it "should store itself" do
    @file.store
    @file.datetime_stored.should be
    @file.datetime_stored.should be_an_instance_of(Time)
  end

  it "should delete itself" do
    @file.delete
    @file.datetime_removed.should be
    @file.datetime_removed.should be_an_instance_of(Time)
  end

  it "should have datetime stamps" do
  end
end
