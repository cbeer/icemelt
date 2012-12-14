require 'namaste'
require 'securerandom'
      require 'securerandom'
module FakeGlacierEndpoint
  class Archive
  	def self.create vault, options = {}
      archive_id = Archive.mint_archive_id
      a = Archive.new(vault, archive_id)
   
      a.description = options.fetch(:archive_description, '')

      a
  	end

  	def self.mint_archive_id
      SecureRandom.urlsafe_base64(138)
  	end

    attr_reader :vault, :id

    def initialize vault, archive_id = nil, options = {}
    	@vault = vault
    	@id = archive_id
    end

    def content= file
      ppath.open('content', 'w') do |f|
        f.write file.to_s
      end
    end

    def description= description
      description_tag.value= description
    end

    def delete
      vault.pairtree.purge! archive_id
    end

    def content
      ppath.read('content')
    end

    def description
      description_tag.value
    end

    def ppath
      @ppath ||= vault.pairtree.mk(id)
    end

    def sha256
      ''
    end

    def description_tag
      dir = Namaste::Dir.new(ppath.path)

      if dir.what.length > 0
        dir.what.first
      else
      	dir.what = ''
      	dir.what.first     
      end
    end
  end
end