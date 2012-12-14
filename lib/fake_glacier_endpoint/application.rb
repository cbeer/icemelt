require 'sinatra'
require 'sinatra/json'
require 'namaste'
require 'pairtree'
require 'anvl'
require 'noid'

module FakeGlacierEndpoint
  class Application < Sinatra::Base
  	# Create Vault
    put ':account_id/vaults/:vault_name' do
      status 201
      headers \
        "Date" => '',
        "Location" => request.fullpath
    end
    
    # Delete Vault
    delete ':account_id/vaults/:vault_name' do
      status 204
      headers \
        "Date" => ''
    end

    # Describe Vault
    get ':account_id/vaults/:vault_name' do
      status 200

      json({
      	'CreationDate' => '',
      	'LastInventoryDate' => '',
      	'NumberOfArchives' => '',
      	'SizeInBytes' => '',
      	'VaultARN' => '',
      	'VaultName' => params[:vault_name]
      })
    end

    # List Vaults
    get ':account_id/vaults' do
      json({

      	})
    end

    # Upload Archive
    post ':account_id/vaults/:vault_name/archives' do
      status 201
    end

    # Delete Archive
    delete ':account_id/vaults/:vault_name/archives' do

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
