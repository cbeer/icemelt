require 'sinatra'
require 'sinatra/json'
require 'namaste'
require 'anvl'
require 'noid'

module FakeGlacierEndpoint
  class Application < Sinatra::Base

    def self.data_root
      @data_root ||= File.expand_path('../../data', File.dirname(__FILE__))
    end

    def data_root
      self.class.data_root
    end

    def vault vault_name
      Vault.find(data_root, vault_name)
    end

  	# Create Vault
    put ':account_id/vaults/:vault_name' do
      status 201
      headers \
        "Date" => '',
        "Location" => request.fullpath
      Vault.create(data_root, params[:vault_name])
    end
    
    # Delete Vault
    delete ':account_id/vaults/:vault_name' do
      status 204
      headers \
        "Date" => ''
      vault(params[:vault_name]).delete
    end

    # Describe Vault
    get ':account_id/vaults/:vault_name' do
      status 200

      v = vault(params[:vault_name])

      json({
      	'CreationDate' => v.create_date,
      	'LastInventoryDate' => v.last_inventory_date,
      	'NumberOfArchives' => v.count,
      	'SizeInBytes' => v.size,
      	'VaultARN' => '',
      	'VaultName' => params[:vault_name]
      })
    end

    # List Vaults
    get ':account_id/vaults' do
      v = Vault.list(data_root)

      json({

      	})
    end

    # Upload Archive
    post ':account_id/vaults/:vault_name/archives' do
      status 201
      v = Archive.create(vault(params[:vault_name]), options)
      v.content = f
    end

    # Delete Archive
    delete ':account_id/vaults/:vault_name/archives/:archive_id' do
      archive_id = nil
      v = Archive.new(vault(params[:vault_name]), params[:archive_id])
    end

    # Multipart Upload

    # Initiate a Job
    post ':account_id/vaults/:vault_name/jobs' do

    end

    # Describe Job
    get ':account_id/vaults/:vault_name/jobs/:job_id' do
      status 201
    end

    # Get Job Output
    get ':account_id/vaults/:vault_name/jobs/:job_id/output' do

    end

    # List Jobs
    get ':account_id/vaults/:vault_name/jobs' do

    end
  end
end
