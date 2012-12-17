require 'spec_helper'

describe Icemelt::Archive do

  before(:all) do
    Icemelt::Vault.create(TEST_DATA_PATH, 'archive_subject_path')
  end

  after(:all) do
    Icemelt::Vault.clear!(TEST_DATA_PATH)
  end

  subject { Icemelt::Archive.create(vault) }

  let(:vault) { Icemelt::Vault.new(TEST_DATA_PATH, 'archive_subject_path') }

  describe ".create" do
    it "should create a new archive" do
      Icemelt::Archive.stub(:mint_archive_id).and_return('qwerty')
      archive = Icemelt::Archive.create(vault, :archive_description => 'ASFD')
  
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
      subject.description.should == nil
    end

    it "should read the namaste tag" do
      subject.description = "PID/DSID"
      
      subject.description.should == "PID/DSID"
    end
  end

  describe "#prepare_for_multipart_upload!" do
    it "should mark this as a multipart upload" do
      subject.should_not be_multipart_upload
      subject.prepare_for_multipart_upload!
      subject.should be_multipart_upload
    end

  end

  describe "#complete_multipart_upload!" do
    it "should end the multipart upload" do
      subject.should_not be_multipart_upload
      subject.prepare_for_multipart_upload!
      subject.complete_multipart_upload!
      subject.should_not be_multipart_upload
    end
  end

  describe "#add_multipart_content" do
    it "should write content directly into the file at the appropriate place" do
      subject.add_multipart_content "a", "a1b2c3", 0, 1
      subject.add_multipart_content "b", "a1b2c3", 2, 3
      subject.add_multipart_content "c", "a1b2c3", 5, 6
      subject.add_multipart_content "d", "a1b2c3", 0, 1

      subject.content.should == "d\0b\0\0c"
      
    end
  end
end