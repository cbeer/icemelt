require 'namaste'
require 'securerandom'
module FakeGlacierEndpoint
  class Archive
  	def self.create vault, options
      archive_id = Archive.mint_archive_id
      a = Archive.new(vault, archive_id)
   
      a.description = options[:archive_description]

      a
  	end

  	def self.mint_archive_id
      require 'securerandom'
      SecureRandom.urlsafe_base64(138)
  	end

    attr_reader :vault, :id

    def initialize vault, archive_id = nil, options = {}
    	@vault = vault
    	@id = archive_id
    end

    def content= file
      ppath.open('content', 'rw') do |f|
        f.write file
      end
    end

    def description= description
      Namaste::Dir.new(ppath.path).what= description
    end

    def delete
      vault.pairtree.purge! archive_id
    end

    def content
      ppath.read('content')
    end

    def description
      Namaste::Dir.new(ppath.path).what
    end

    def ppath
      vault.pairtree.mk(archive_id)
    end
  end
end