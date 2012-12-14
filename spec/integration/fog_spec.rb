require 'spec_helper'
require 'fog'

describe "Fog Integration Spec", :acceptance => true do
  before(:all) do
  	begin
      vault = subject.vaults.get 'myvault'
      vault.destroy
    rescue => e
      puts e.inspect
    end
  end

  subject { Fog::AWS::Glacier.new :aws_access_key_id => '', :aws_secret_access_key => '', :scheme => 'http', :host => 'localhost', :port => '3000'}

  it "should create vaults" do
  	subject.vaults.create :id => 'myvault'
  end

  it "should list vault" do
    subject.vaults.should have(1).item
  end

  it "should add archives to vaults" do
    vault = subject.vaults.get 'myvault'

    vault.archives.create :body => 'asdfgh', :multipart_chunk_size => 1024*1024
  end

  it "should list inventories" do
    vault = subject.vaults.get 'myvault'

    job = vault.jobs.create :type => Fog::AWS::Glacier::Job::INVENTORY

    job.wait_for {ready?}

    json = JSON.parse(job.get_output.body)

    json['ArchiveList'].should have_at_least(1).archive
  end

  it "should retrieve content" do
    vault = subject.vaults.get 'myvault'

    archive = vault.archives.create :body => 'asdfgh', :multipart_chunk_size => 1024*1024

    job = vault.jobs.create(:type => Fog::AWS::Glacier::Job::ARCHIVE, :archive_id => archive.id)

    job.wait_for {ready?}

    job.get_output.body.should == 'asdfgh'
  end
end