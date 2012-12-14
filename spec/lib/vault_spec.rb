require 'spec_helper'

describe FakeGlacierEndpoint::Vault do
  after(:each) do
    FakeGlacierEndpoint::Vault.clear!(TEST_DATA_PATH)
  end

  subject {
  	FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'subject_vault')
  }

  describe ".clear!" do
    it "should work" do
      # FileUtils.should_receive(:rm_r).with(TEST_DATA_PATH, :force => true).at_least(1).time
      FakeGlacierEndpoint::Vault.clear!(TEST_DATA_PATH)
    end
  end

  describe ".create" do
  	it "should create a vault in the data root" do
      vault = FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
  	  File.exists?(File.join(TEST_DATA_PATH, 'fake_vault_name'))
  	end

  	it "should raise errors if the vault already exists" do
      vault = FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name2')

      expect {
        FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name2')
      }.to raise_error
  	end
  end

  describe ".list" do
  	it "should list existing vaults" do
      FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name2')
      FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name3')
      FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name4')

      FakeGlacierEndpoint::Vault.list(TEST_DATA_PATH).map { |x| x.vault_name }.should include('fake_vault_name', 'fake_vault_name2', 'fake_vault_name3', 'fake_vault_name4')
  	end
  end

  describe "#exists?" do
    it "should be true if the vault directory exists" do
      vault = FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      vault.should exist
    end

    it "should be false otherwise" do
      v = FakeGlacierEndpoint::Vault.new(TEST_DATA_PATH, 'this_doesnt_exist')
      v.should_not exist
    end
  end

  # no-op
  describe "#delete" do; end

  describe "create_date" do
  	it "should be the directory ctime" do
      t = Time.now
      vault = FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      t1 = Time.now
      vault.create_date.should be_within(1 + (t1 - t)).of(t)
  	end
  end

  describe "#last_inventory_date" do

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
       subject.size.should == 124 # 124 happens to be the size of a blank pairtree
    end
  end

end