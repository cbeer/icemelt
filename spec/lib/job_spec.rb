require 'spec_helper'

describe Icemelt::Job do
  describe ".create" do
  	it "should create a new job with a random job it" do
  	  old_id = Icemelt::Job.mint_job_id
  	  vault_mock = mock(:add_job => true)
      job = Icemelt::Job.create vault_mock, 'Type' => 'archive-retrieval' 

      job.id.should be > old_id
      job.should be_a_kind_of(Icemelt::Job)
  	end
  end

  let(:vault) { vault_mock = mock(:add_job => true) }
  subject { Icemelt::Job.create(vault, 'ArchiveId' => 'asdf',  'Type' => @job_type || 'archive-retrieval') }

  describe "#type" do
  	it "should look in the options" do
      job = Icemelt::Job.new(mock, 'asdf', 'Type' => 'custom-type')
      job.type.should == 'custom-type'
  	end
  end

  describe '#action' do

  	it "return an action value appropriate for the aws attributes" do
  	  subject.stub(:type => 'archive-retrieval')
  	  subject.action.should == 'ArchiveRetrieval'

  	  subject.stub(:type => 'inventory-retrieval')
  	  subject.action.should == 'InventoryRetrieval'
  	end

  end

  describe "#archive_retreival?" do
    it "should be true if the job is an archive retrieval" do
  	  subject.stub(:type => 'archive-retrieval')
  	  subject.should be_archive_retrieval
    end
  end

  describe "#archive" do
  	it "should be a reference to the archive for retrieval" do
  	  subject.vault.should_receive(:archive).with('asdf')
      subject.archive
  	end
  end

  describe "#content" do
  	it "should be the archive contents" do
  	  subject.vault.should_receive(:archive).with('asdf').and_return(mock(:content => '123'))
      subject.content.should == '123'
      
  	end

  end

  describe "#save" do
  	it "should ask the vault to persist it" do
  	  subject.vault.should_receive(:add_job).with(subject)
      subject.save
  	end
  end

  describe "#aws_attributes" do

  end

  describe "#status" do
  	it "should have these permutations:" do
      subject.stub(:complete? => true)
      subject.status.should == "Complete"

      subject.stub(:complete? => false)
      subject.status.should == "InProgress"
  	end
  end



end