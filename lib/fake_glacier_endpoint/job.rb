
module FakeGlacierEndpoint
  class Job
  	def self.create vault, options
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

    def save
      vault.add_job(id, @options)
    end

    def to_json
    	puts options.inspect
      { 'JobID' => id, 'Type' => options['Type'] }
    end


    private
    
  end
end