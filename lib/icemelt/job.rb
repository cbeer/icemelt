
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
    end

    def type
      options['Type']
    end

    def content
    	case type
    	  when "archive-retrieval"
    	  	vault.archive(options["ArchiveId"]).content
    	  when "inventory-retrieval"
    	  	vault.archives
    	end
    end

    def save
      vault.add_job(id, @options)
    end

    def aws_attributes
      options.merge({ 'JobID' => id, "Completed" => true })
    end


    private
    
  end
end