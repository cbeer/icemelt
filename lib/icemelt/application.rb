require 'sinatra'
require 'json'
require 'namaste'
require 'anvl'
require 'noid'

module Icemelt
  class Application < Sinatra::Base

    enable  :sessions, :logging

    def self.data_root
      @data_root ||= ENV['DATA_ROOT'] || File.expand_path('../../data', File.dirname(__FILE__))
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
        "Date" => Time.now.strftime('%c'),
        "Location" => "#{params[:account_id]}/vaults/#{params[:vault_name]}"
      Vault.create(data_root, params[:vault_name])

      nil
    end
    
    # Delete Vault
    delete '/:account_id/vaults/:vault_name' do
      status 204
      headers \
        "Date" => Time.now.strftime('%c')
      vault(params[:vault_name]).delete

      nil
    end

    # Describe Vault
    get '/:account_id/vaults/:vault_name' do
      begin
        v = vault(params[:vault_name])
        status 200

        headers \
          "Content-Type" => 'application/json'

        v.aws_attributes.to_json
      rescue
        status 404
        return
      end
    end

    # List Vaults
    get '/:account_id/vaults' do
      vaults = Vault.list(data_root)

      status 200

      headers \
        "Content-Type" => 'application/json'

      {
        "Marker" => nil,
        "VaultList" => vaults.map(&:aws_attributes)
      	}.to_json

    end

    # Upload Archive
    post '/:account_id/vaults/:vault_name/archives' do
      status 201

      options = {}
      options[:archive_description] = request.env['HTTP_X_AMZ_ARCHIVE_DESCRIPTION']
      
      a = Archive.create(vault(params[:vault_name]), options)
      a.content = request.body.read
      a.save

      headers \
        "Date" => Time.now.strftime('%c'),
        "x-amz-sha256-tree-hash" => a.sha256,
        "Location" => "/#{params[:account_id]}/vaults/#{params[:vault_name]}/archives/#{a.id}",
        "x-amz-archive-id" => a.id

      nil  
    end

    post '/:account_id/vaults/:vault_name/multipart-uploads' do
      status 201

      options = {}
      options[:archive_description] = request.env['HTTP_X_AMZ_ARCHIVE_DESCRIPTION']
      
      a = Archive.create(vault(params[:vault_name]), options)
      a.prepare_for_multipart_upload!

      headers \
        "Date" => Time.now.strftime('%c'),
        "x-amz-sha256-tree-hash" => a.sha256,
        "Location" => "/#{params[:account_id]}/vaults/#{params[:vault_name]}/multipart-uploads/#{a.id}",
        "x-amz-multipart-upload-id" => a.id

      nil
    end

    post '/:account_id/vaults/:vault_name/multipart-uploads/:archive_id' do
      status 201

      a = vault(params[:vault_name]).archive(params[:archive_id])

      if a.multipart_upload?
        a.complete_multipart_upload!
      else
      end
      
      headers \
        "Date" => Time.now.strftime('%c'),
        "x-amz-sha256-tree-hash" => a.sha256,
        "Location" => "/#{params[:account_id]}/vaults/#{params[:vault_name]}/archives/#{a.id}",
        "x-amz-archive-id" => a.id

      nil  

    end

    put '/:account_id/vaults/:vault_name/multipart-uploads/:archive_id' do
      status 204

      a = vault(params[:vault_name]).archive(params[:archive_id])
      raise "This isn't a multipart upload; #{a.inspect}" unless a.multipart_upload?
      from, to = request.env['HTTP_CONTENT_RANGE'].scan(/bytes (\d+)-(\d+)/).first
      hash = request['x-amz-sha256-tree-hash']
      a.add_multipart_content(request.body.read, hash, from.to_i, to.to_i)

      puts Dir.glob(File.join(a.ppath, '*')).inspect
      headers \
        "Date" => Time.now.strftime('%c')

      nil
    end

    delete '/:account_id/vaults/:vault_name/multipart-uploads/:archive_id' do
      status 204

      vault(params[:vault_name]).archive(params[:archive_id]).delete
    
      headers \
        "Date" => Time.now.strftime('%c')

      nil
    end

    # Delete Archive
    delete '/:account_id/vaults/:vault_name/archives/:archive_id' do
      status 204

      vault(params[:vault_name]).archive(params[:archive_id]).delete
    
      headers \
        "Date" => Time.now.strftime('%c')

      nil
    end

    # Multipart Upload

    # Initiate a Job
    post '/:account_id/vaults/:vault_name/jobs' do
      status 202

      options = JSON.parse(request.body.read)
      job = Job.create(vault(params[:vault_name]), options)

      headers \
        "Location" => "#{params[:account_id]}/vaults/#{params[:vault_name]}/jobs/#{job.id}",
        'x-amz-job-id' => job.id.to_s

      nil
    end

    # Describe Job
    get '/:account_id/vaults/:vault_name/jobs/:job_id' do
      status 200

      headers \
        "Content-Type" => 'application/json'

      job = vault(params[:vault_name]).job params[:job_id]

      job.aws_attributes.to_json
    end

    # Get Job Output
    get '/:account_id/vaults/:vault_name/jobs/:job_id/output' do
      v = vault(params[:vault_name])
      job = v.job params[:job_id]

      raise "??" if job.expired?

      # what happens if the job was expired?

      case job.type
        when "archive-retrieval"
          job.content
        when "inventory-retrieval"
          {
            "VaultARN" => v.arn,
            "InventoryDate" => Time.now.strftime('%c'),
            "ArchiveList" => job.content.map { |x| x.aws_attributes }
          }.to_json
      end
    end

    # List Jobs
    get '/:account_id/vaults/:vault_name/jobs' do
      jobs = vault(params[:vault_name]).jobs

      headers \
        "Content-Type" => 'application/json'

      {
        "JobList" => jobs.map(&:aws_attributes)
        }.to_json
    end
  end
end
