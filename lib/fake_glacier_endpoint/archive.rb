require 'namaste'
require 'securerandom'
module FakeGlacierEndpoint
  class Archive
  	def self.create vault, options = {}
      archive_id = Archive.mint_archive_id
      a = Archive.new(vault, archive_id)
   
      a.description = options[:archive_description] unless options[:archive_description].nil? or options[:archive_description].empty?
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
      tags = Namaste::Dir.new(ppath.path).what
      if tags.first
        tags.first.vaule = description
      else
        Namaste::Dir.new(ppath.path).what = description
      end
    end

    def delete
      vault.pairtree.purge! archive_id
    end

    def content
      ppath.read('content')
    end

    def description
      Namaste::Dir.new(ppath.path).what.first.value rescue nil
    end

    def ppath
      @ppath ||= vault.pairtree.mk(id)
    end

    def sha256
      ''
    end

    def aws_attributes
      { "ArchiveId" => id }
    end
  end
end