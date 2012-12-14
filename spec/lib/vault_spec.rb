require 'spec_helper'
require 'fileutils'

describe FakeGlacierEndpoint::Vault do
  describe ".create" do
  	after(:each) do
      FakeGlacierEndpoint::Vault.clear!(TEST_DATA_PATH)
   	end

  	it "should create a vault in the data root" do
      vault = FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
  	  File.exists?(File.join(TEST_DATA_PATH, 'fake_vault_name'))
  	end

  	it "should raise errors if the vault already exists" do
      vault = FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name')

      expect {
        FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      }.to raise_error
  	end
  end

  describe ".list" do
    after(:each) do
      FakeGlacierEndpoint::Vault.clear!(TEST_DATA_PATH)
   	end

  	it "should list existing vaults" do
      FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name')
      FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name2')
      FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name3')
      FakeGlacierEndpoint::Vault.create(TEST_DATA_PATH, 'fake_vault_name4')

      FakeGlacierEndpoint::Vault.list(TEST_DATA_PATH).to_a.should include('fake_vault_name', 'fake_vault_name2', 'fake_vault_name3', 'fake_vault_name4')
  	end
  end
end