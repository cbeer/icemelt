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
      	'VaultARN' => v.id,
      	'VaultName' => params[:vault_name]
      })
    end

    # List Vaults
    get ':account_id/vaults' do
      vaults = Vault.list(data_root)

      status 200

      json({
        "Marker" => nil,
        "VaultList" => 
           vaults.map { |v|
             {
               "CreationDate" => v.create_date,
               "LastInventoryDate" => v.last_inventory_date,
               "NumberOfArchives" => v.count,
               "SizeInBytes" => v.size,
               "VaultARN" => v.id,
               "VaultName" => v.id
             }
           }
        

      	})
    end

    # Upload Archive
    post ':account_id/vaults/:vault_name/archives' do
      status 201
      a = Archive.create(vault(params[:vault_name]), options)
      a.content = f

      headers \
        "Date" => Time.now,
        "x-amz-sha256-tree-hash" => a.sha256,
        "Location" => '',
        "x-amz-archive-id" => a.id
    end

    # Delete Archive
    delete ':account_id/vaults/:vault_name/archives/:archive_id' do
      status 204

      Archive.new(vault(params[:vault_name]), params[:archive_id]).delete
    
      headers \
        "Date" => Time.now
    end

    # Multipart Upload

    # Initiate a Job
    post ':account_id/vaults/:vault_name/jobs' do
      status 202

      job = Job.create(vault(params[:vault_name]), type, options)

      headers \
        "Location" => "#{params[:account_id]}/vaults/#{params[:vault_name]}/jobs/#{job.id}",
        'x-amz-job-id' => job.id
    end

    # Describe Job
    get ':account_id/vaults/:vault_name/jobs/:job_id' do
      status 201

      job = Job.new(vault(params[:vault_name]), params[:job_id])

      json({
        "JobId" => job.id
      })
    end

    # Get Job Output
    get ':account_id/vaults/:vault_name/jobs/:job_id/output' do
      job = Job.new(vault(params[:vault_name]), params[:job_id])
      return job.content
    end

    # List Jobs
    get ':account_id/vaults/:vault_name/jobs' do
      jobs = vault(params[:vault_name]).jobs

      json({
        "JobList" => jobs.map { |j|
          {
            "JobId" => j.id
          }
        }
        })
    end
  end
end
