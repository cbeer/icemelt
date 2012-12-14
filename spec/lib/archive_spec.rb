require 'spec_helper'

describe FakeGlacierEndpoint::Archive do

  before(:all) do
    FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'archive_subject_path')
  end

  after(:all) do
    FakeGlacierEndpoint::Vault.clear!(TEST_DATA_PATH)
  end

  subject { FakeGlacierEndpoint::Archive.create(vault) }

  let(:vault) { FakeGlacierEndpoint::Vault.new(TEST_DATA_PATH, 'archive_subject_path') }

  describe ".create" do
    it "should create a new archive" do
      FakeGlacierEndpoint::Archive.stub(:mint_archive_id).and_return('qwerty')
      archive = FakeGlacierEndpoint::Archive.create(vault, :archive_description => 'ASFD')
  
      archive.id.should == "qwerty"
      archive.description.should == 'ASFD'

    end
  end

  describe "#content" do
  	it "should read the content from the content file in the ppath" do
      subject.ppath.stub(:read).and_return('asdf')
      subject.content.should == "asdf"
  	end
  end

  describe "#content=" do
  	it "should write the content to a file" do
      subject.content = "asdf"
      subject.ppath.read('content').should == "asdf"
  	end
  end

  describe "#description=" do
    it "should write a namaste tag" do
      subject.description = "PID/DSID"
      Namaste::Dir.new(subject.ppath.path).what.first.value.should == "PID/DSID"
    end
  end

  describe "#description" do
    it "the description should be empty by default" do
      subject.description.should == ''
    end

    it "should read the namaste tag" do
      subject.description = "PID/DSID"
      
      subject.description.should == "PID/DSID"
    end
  end
end