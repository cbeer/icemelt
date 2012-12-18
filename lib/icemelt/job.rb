
module Icemelt
  class Job
  	def self.create vault, options
  		raise unless ['archive-retrieval', 'inventory-retrieval'].include? options['Type']
  	  j = Job.new(vault, self.mint_job_id, options)
      j.save

      j
  	end

  	def self.mint_job_id
      @@i ||= 0
      @@i += 1
  	end

    attr_reader :vault, :id, :options
    def initialize vault, id, options = {}
      @vault = vault
      @id = id
      @options = options
      @options['CreationDate'] ||= Time.now
      randomize_completion_time
      configure_job_expiration_time
    end

    def type
      options['Type']
    end

    def action
      case type
        when "archive-retrieval"
          "ArchiveRetrieval"
        when "inventory-retrieval" 
          "InventoryRetrieval" 
      end
    end

    def archive_retrieval?
      type == 'archive-retrieval'
    end

    def archive
       vault.archive(options["ArchiveId"])
    end

    def content
    	case type
    	  when "archive-retrieval"
    	  	archive.content
    	  when "inventory-retrieval"
    	  	vault.archives
    	end
    end

    def save
      vault.add_job(id, @options)
    end

    def aws_attributes
      {
        'Action' => action,
        'ArchiveId' => options['ArchiveId'],
        'ArchiveSizeInBytes' => (archive.size if archive_retrieval?),
        'ArchiveSHA256TreeHash' => (archive.sha256 if archive_retrieval?),
        'Completed' => complete?,
        'CompletionDate' => (options['completion_time'] if complete?),
        'CreationDate' => options['CreationDate'],
        'InventorySizeInBytes' => 0,
        'JobDescription' => options['Description'],
        'JobId' => id,
        'RetrievalByteRange' => options["RetrievalByteRange"],
        'SHA256TreeHash' => (archive.sha256 if archive_retrieval?),
        'SNSTopic' => options['SNSTopic'],
        'StatusCode' => status,
        'StatusMessage' => '',
        'VaultARN' => vault.arn
      }
    end

    def status
      if complete?
        "Complete"
      else
        "InProgress"
      end
    end

    def complete?
      Time.now > options['completion_time']
    end

    def expired?
      Time.now > options['expiration_time']
    end


    private
    def randomize_completion_time
      options['completion_time'] ||= Time.now + Random.rand(60)
    end

    def configure_job_expiration_time
      options['expiration_time'] ||= Time.now + 60*60*24
    end
  end
end