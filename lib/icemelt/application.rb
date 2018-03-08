require 'sinatra'
require 'json'
require 'namaste'
require 'anvl'
require 'noid'
require 'csv'

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
      Vault.new(data_root, vault_name)
    end

    def common_response_headers
      headers \
        "Date" => Time.now.strftime('%c'),
        "x-amzn-RequestId" => Time.now.strftime('%c')
    end

  	# Create Vault
    put '/:account_id/vaults/:vault_name' do
      status 201
      
      common_response_headers

      headers \
        "Location" => "#{params[:account_id]}/vaults/#{params[:vault_name]}"
      Vault.create(data_root, params[:vault_name])

      nil
    end
    
    # Delete Vault
    delete '/:account_id/vaults/:vault_name' do
      v = vault(params[:vault_name])
      common_response_headers
      if v.exists?  
        status 204
        v.delete
        nil
      else
        status 404
        headers \
          "Content-Type" => 'application/json'
        ({
          "code"    => "ResourceNotFoundException",
          "message" => "Vault not found for ARN: " + v.arn,
          "type"    => "Client"
        }).to_json
      end

    end

    # Describe Vault
    get '/:account_id/vaults/:vault_name' do
      common_response_headers
      headers \
        "Content-Type" => 'application/json'
      begin
        v = vault(params[:vault_name])
        status 200


        v.aws_attributes.to_json
      rescue
        status 404
        ({
          "code"    => "ResourceNotFoundException",
          "message" => "Vault not found for ARN: " + v.arn,
          "type"    => "Client"
        }).to_json
      end
    end

    # List Vaults
    get '/:account_id/vaults' do
      vaults = Vault.list(data_root)

      status 200
      common_response_headers

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
      common_response_headers

      options = {}
      options[:archive_description] = request.env['HTTP_X_AMZ_ARCHIVE_DESCRIPTION']
      
      a = Archive.create(vault(params[:vault_name]), options)
      a.content = request.body.read
      a.save

      headers \
        "x-amz-sha256-tree-hash" => a.sha256,
        "Location" => "/#{params[:account_id]}/vaults/#{params[:vault_name]}/archives/#{a.id}",
        "x-amz-archive-id" => a.id

      nil  
    end

    post '/:account_id/vaults/:vault_name/multipart-uploads' do
      status 201
      common_response_headers

      options = {}
      options[:archive_description] = request.env['HTTP_X_AMZ_ARCHIVE_DESCRIPTION']
      
      a = Archive.create(vault(params[:vault_name]), options)
      a.prepare_for_multipart_upload!

      headers \
        "x-amz-sha256-tree-hash" => a.sha256,
        "Location" => "/#{params[:account_id]}/vaults/#{params[:vault_name]}/multipart-uploads/#{a.id}",
        "x-amz-multipart-upload-id" => a.id

      nil
    end

    post '/:account_id/vaults/:vault_name/multipart-uploads/:archive_id' do
      status 201
      common_response_headers

      a = vault(params[:vault_name]).archive(params[:archive_id])

      if a.multipart_upload?
        a.complete_multipart_upload!
      else
      end
      
      headers \
        "x-amz-sha256-tree-hash" => a.sha256,
        "Location" => "/#{params[:account_id]}/vaults/#{params[:vault_name]}/archives/#{a.id}",
        "x-amz-archive-id" => a.id

      nil  

    end

    put '/:account_id/vaults/:vault_name/multipart-uploads/:archive_id' do
      status 204
      common_response_headers

      a = vault(params[:vault_name]).archive(params[:archive_id])
      raise "This isn't a multipart upload; #{a.inspect}" unless a.multipart_upload?
      from, to = request.env['HTTP_CONTENT_RANGE'].scan(/bytes (\d+)-(\d+)/).first
      hash = request['x-amz-sha256-tree-hash']
      a.add_multipart_content(request.body.read, hash, from.to_i, to.to_i)

      nil
    end

    delete '/:account_id/vaults/:vault_name/multipart-uploads/:archive_id' do
      status 204
      common_response_headers

      vault(params[:vault_name]).archive(params[:archive_id]).delete
  

      nil
    end

    # Delete Archive
    delete '/:account_id/vaults/:vault_name/archives/:archive_id' do
      status 204
      common_response_headers

      vault(params[:vault_name]).archive(params[:archive_id]).delete
    
      nil
    end

    # Multipart Upload

    # Initiate a Job
    post '/:account_id/vaults/:vault_name/jobs' do
      common_response_headers

      v = vault(params[:vault_name])

      if v.exists?      
        status 202

        options = JSON.parse(request.body.read)
        job = Job.create(v, options)

        headers \
          "Location" => "#{params[:account_id]}/vaults/#{params[:vault_name]}/jobs/#{job.id}",
          'x-amz-job-id' => job.id.to_s

        nil
      else
        status 404
        headers \
          "Content-Type" => 'application/json'

        ({
          "code"    => "ResourceNotFoundException",
          "message" => "Vault not found for ARN: " + v.arn,
          "type"    => "Client"
        }).to_json
      end
    end

    # Describe Job
    get '/:account_id/vaults/:vault_name/jobs/:job_id' do
      common_response_headers
      
      v = vault(params[:vault_name])
      job = v.job(params[:job_id])
      
      if job.expired?
        headers \
          "Content-Type" => 'application/json'
          status 404
        
        return ({
          "code"    => "ResourceNotFoundException",
          "message" => "The job ID was not found: #{job.id}",
          "type"    => "Client"
        }).to_json
      end

      status 200

      headers \
        "Content-Type" => 'application/json'

      job = vault(params[:vault_name]).job params[:job_id]

      job.aws_attributes.to_json
    end

    # Get Job Output
    get '/:account_id/vaults/:vault_name/jobs/:job_id/output' do
      common_response_headers
      v = vault(params[:vault_name])
      job = v.job params[:job_id]

      if job.expired? or job.new?
        headers \
          "Content-Type" => 'application/json'
          status 404
        
        return ({
          "code"    => "ResourceNotFoundException",
          "message" => "The job ID was not found: #{job.id}",
          "type"    => "Client"
        }).to_json
      end

      case job.type
        when "archive-retrieval"
          job.content
        when "inventory-retrieval"
          case job.format
            when 'JSON'
              headers \
                "Content-Type" => 'application/json'

              {
                "VaultARN" => v.arn,
                "InventoryDate" => Time.now.strftime('%c'),
                "ArchiveList" => job.content.map { |x| x.aws_attributes }
              }.to_json
            when 'CSV'
              headers \
                "Content-Type" => 'text/csv'

              CSV.generate do |csv|
                csv << ["ArchiveId", "ArchiveDescription", "CreationDate", "Size", "SHA256TreeHash"]
                job.content.each do |x|
                  csv << [x.id, x.description, x.create_date, x.size, x.sha256]
                end
              end  

          end
      end
    end

    # List Jobs
    get '/:account_id/vaults/:vault_name/jobs' do
      common_response_headers

      jobs = vault(params[:vault_name]).jobs

      headers \
        "Content-Type" => 'application/json'

      {
        "JobList" => jobs.map(&:aws_attributes)
        }.to_json
    end
  end
end
