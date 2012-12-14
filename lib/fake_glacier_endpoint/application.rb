require 'sinatra'
require 'json'
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
    put '/:account_id/vaults/:vault_name' do
      status 201
      headers \
        "Date" => '',
        "Location" => request.fullpath
      Vault.create(data_root, params[:vault_name])

      nil
    end
    
    # Delete Vault
    delete '/:account_id/vaults/:vault_name' do
      status 204
      headers \
        "Date" => ''
      vault(params[:vault_name]).delete

      nil
    end

    # Describe Vault
    get '/:account_id/vaults/:vault_name' do
      status 200

      v = vault(params[:vault_name])
      headers \
        "Content-Type" => 'application/json'

      v.to_json
    end

    # List Vaults
    get '/:account_id/vaults' do
      vaults = Vault.list(data_root)

      status 200

      headers \
        "Content-Type" => 'application/json'

      {
        "Marker" => nil,
        "VaultList" => vaults.map(&:to_json)
      	}.to_json

    end

    # Upload Archive
    post '/:account_id/vaults/:vault_name/archives' do
      status 201

      options = {}
      options[:archive_description] = request['x-amz-archive-description']
      
      a = Archive.create(vault(params[:vault_name]), options)
      a.content = request.body.read

      headers \
        "Date" => Time.now.strftime('%c'),
        "x-amz-sha256-tree-hash" => a.sha256,
        "Location" => "/#{params[:account_id]}/vaults/#{params[:vault_name]}/archives/#{a.id}",
        "x-amz-archive-id" => a.id

      nil  
    end

    # Delete Archive
    delete '/:account_id/vaults/:vault_name/archives/:archive_id' do
      status 204

      Archive.new(vault(params[:vault_name]), params[:archive_id]).delete
    
      headers \
        "Date" => Time.now

      nil
    end

    # Multipart Upload

    # Initiate a Job
    post '/:account_id/vaults/:vault_name/jobs' do
      status 202

      options = JSON.parse(request.body.read)
      puts options.inspect

      job = Job.create(vault(params[:vault_name]), options)

      headers \
        "Location" => "#{params[:account_id]}/vaults/#{params[:vault_name]}/jobs/#{job.id}",
        'x-amz-job-id' => job.id.to_s

      job.id.to_s
    end

    # Describe Job
    get '/:account_id/vaults/:vault_name/jobs/:job_id' do
      status 201

      job = vault(params[:vault_name]).jobs[params[:job_id]]

      job.to_json
    end

    # Get Job Output
    get '/:account_id/vaults/:vault_name/jobs/:job_id/output' do
      job = vault(params[:vault_name]).jobs[params[:job_id]]
      return job.content
    end

    # List Jobs
    get '/:account_id/vaults/:vault_name/jobs' do
      jobs = vault(params[:vault_name]).jobs

      {
        "JobList" => jobs.map(&:to_json)
        }.to_json
    end
  end
end
