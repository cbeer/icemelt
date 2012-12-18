require 'spec_helper'

describe Icemelt::Vault do
  after(:each) do
    Icemelt::Vault.clear!(TEST_DATA_PATH)
  end

  subject {
  	Icemelt::Vault.create(TEST_DATA_PATH, 'subject_vault')
  }

  describe ".clear!" do
    it "should work" do
      # FileUtils.should_receive(:rm_r).with(TEST_DATA_PATH, :force => true).at_least(1).time
      Icemelt::Vault.clear!(TEST_DATA_PATH)
    end
  end

  describe ".create" do
  	it "should create a vault in the data root" do
      vault = Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
  	  File.exists?(File.join(TEST_DATA_PATH, 'fake_vault_name'))
  	end

    it "should be idempotent" do
      expect {
      Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      }.to_not raise_error
    end
  end

  describe ".find" do

    it "should return a new vault" do
      vault = Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      vault.should be_a_kind_of(Icemelt::Vault)
    end

    it "should raise an error if the vault doesn't already exist" do
      expect { Icemelt::Vault.find(TEST_DATA_PATH, 'this_vault_does_not_exist') }.to raise_error
    end
  end

  describe ".list" do
  	it "should list existing vaults" do
      Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name2')
      Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name3')
      Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name4')

      Icemelt::Vault.list(TEST_DATA_PATH).map { |x| x.vault_name }.should include('fake_vault_name', 'fake_vault_name2', 'fake_vault_name3', 'fake_vault_name4')
  	end
  end

  describe "#id" do
    it "should be the vault name" do
       Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name').id.should == 'fake_vault_name'
    end
  end

  describe "#exists?" do
    it "should be true if the vault directory exists" do
      vault = Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      vault.should exist
    end

    it "should be false otherwise" do
      v = Icemelt::Vault.new(TEST_DATA_PATH, 'this_doesnt_exist')
      v.should_not exist
    end
  end

  # no-op
  describe "#delete" do; end

  describe "create_date" do
  	it "should be the directory ctime" do
      t = Time.now
      vault = Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      t1 = Time.now
      vault.create_date.should be_within(1 + (t1 - t)).of(t)
  	end
  end

  describe "#last_inventory_date" do
    it "should be the directory ctime" do
      t = Time.now
      vault = Icemelt::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      t1 = Time.now
      vault.last_inventory_date.should be_within(1 + (t1 - t)).of(t)
    end
  end

  describe "#count" do
    it "should be the list of pairtree directories in the vault" do
      subject.count.should == 0 # subject starts out empty
    end

    it "should be the list of directories in the vault" do
      subject.pairtree.mk('abc')
      subject.pairtree.mk('def')
      subject.pairtree.mk('ghi')
      subject.pairtree.mk('jkl')
      subject.pairtree.mk('mno')
      subject.count.should == 5 # subject starts out empty
    end
  end

  describe "#size" do
    it "should be the size of all the archives under it" do
       subject.size.should == 0
    end

    it "should increase as we add archives" do
      expect {
      a = Icemelt::Archive.create(subject)
      a.content = "asdf"
      a.save
      }.to change { subject.size }.by(4)
    end
  end

  describe "#jobs" do
    it "should fetch the jobs for this vault" do
      subject.jobs.should be_empty

      subject.add_job mock(:id => 1, :options => {:a => 1})
      subject.add_job mock(:id => 2, :options => {:a => 1})
      subject.add_job mock(:id => 3, :options => {:a => 1})

      subject.jobs.should have(3).items
    end

  end

  describe "#job" do
    it "should retrieve a single job" do
      subject.add_job mock(:id => 1, :options => {:a => 1})
      j = subject.job(1)
      j.options[:a].should == 1
    end
  end

  describe "#add_job" do
    it "should add a job to the DBM store" do
      subject.add_job mock(:id => 1, :options => {:a => 1})
      subject.send(:dbm)['1'].should == Marshal.dump({:a => 1})
    end

    it "should flush the DBM handle after committing" do
      m = mock(:store => true)
      m.should_receive(:close)
      subject.stub(:dbm).and_return(m)

      subject.add_job mock(:id => 1, :options => {})
    end


  end

  describe "#archives" do
    it "should list the archives in the vault pairtree" do
      a = Icemelt::Archive.create(subject); a.save
      b = Icemelt::Archive.create(subject); b.save
      c = Icemelt::Archive.create(subject); c.save

      subject.archives.to_a.should include(a,b,c)
    end
  end

  describe "#archive" do
    it "should return an archive for that id" do
      subject.archive('1').id.should == '1'
    end

  end

  describe "#aws_attributes" do
    it "should be a hash of AWS json attributes" do
      subject.aws_attributes.should include('CreationDate' => subject.create_date, 'LastInventoryDate' => subject.last_inventory_date, 'NumberOfArchives' => subject.count, 'SizeInBytes' => subject.size, 'VaultARN' => subject.arn, 'VaultName' => subject.id )
    end
  end

  describe "#arn" do
    it "should make up a URI for the vault" do
      require 'uri'
      URI.parse(subject.arn).scheme.should == 'arn'
    end
  end


end