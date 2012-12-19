require 'namaste'
require 'securerandom'
require 'fog'
module Icemelt
  class Archive
    ##
    # Create a new archive package
    # @param [Icemelt::Vault] vault
    # @param [Hash] options
  	def self.create vault, options = {}
      archive_id = Archive.mint_archive_id
      a = Archive.new(vault, archive_id)
   
      a.description = options[:archive_description] unless options[:archive_description].nil? or options[:archive_description].empty?
      a
  	end

    ##
    # Mint a new archive ID
  	def self.mint_archive_id
      SecureRandom.urlsafe_base64(138)
  	end

    attr_reader :vault, :id

    ##
    # 
    # @param [Icemelt::Vault]
    # @param [String]
    # @param [Hash]
    def initialize vault, archive_id = nil, options = {}
    	@vault = vault
    	@id = archive_id
      @options = options
    end

    ##
    # Add content to the archove
    #
    # @param [#to_s]
    def content= io
      @content = io
    end

    ##
    # Save the content to the file
    def save
      @content.rewind if @content.respond_to? :rewind
      ppath.open('content', 'w') do |f|
        f.write @content.to_s
      end
    end

    ##
    # Add a description to the archive
    #
    # @param [String] 
    def description= description
      tags = Namaste::Dir.new(ppath.path).what
      if tags.first
        tags.first.value = description
      else
        Namaste::Dir.new(ppath.path).what = description
      end
    end


    ##
    # Delete the archive from the data store
    #
    def delete
      vault.pairtree.purge! id
      @id = nil
      @vault = nil
      @ppath = nil
    end

    ##
    # Read the content from archive
    #
    def content
      ppath.read('content')
    end

    ##
    # Archive description
    #
    def description
      Namaste::Dir.new(ppath.path).what.first.value rescue nil
    end

    ##
    # Find the archive in the vault
    #
    def ppath
      @ppath ||= vault.pairtree.mk(id)
    end

    ##
    # Calculate the sha256 for the content
    def sha256
      Fog::AWS::Glacier::TreeHash.digest(File.read(content_path)) if exists?
    end

    ##
    # Path to the content file
    def content_path
      File.join(ppath.path, 'content')
    end

    ##
    # Does the content exist?
    def exists?
      File.exists?(content_path)
    end

    ##
    # Calculate the size of the archive
    def size
      if exists?
        File.size(content_path)
      else
        0
      end
    end

    ##
    # Get the archive create date
    def create_date
      return File.ctime(content_path) if exists?
      File.ctime(ppath.path)
    end

    ##
    # Attributes for AWS JSON responses
    def aws_attributes
      { 
        "ArchiveId" => id,
        "ArchiveDescription" => description,
        "CreationDate" => create_date,
        "Size" => size,
        "SHA256TreeHash" => sha256
       }
    end

    ##
    # Mark this as a multipart upload archive
    def prepare_for_multipart_upload!
      FileUtils.touch(File.join(ppath.path, '.MULTIPART_UPLOAD'))
    end

    ##
    # Finalize the multipart upload
    def complete_multipart_upload!
      FileUtils.rm(File.join(ppath.path, '.MULTIPART_UPLOAD'))
    end

    ##
    # Is this archive a multipart upload?
    def multipart_upload?
      File.exists? File.join(ppath.path, '.MULTIPART_UPLOAD')
    end

    ##
    # Add multipart content to the file
    def add_multipart_content content, hash, from, to
      raise "This isn't a multipart upload" unless multipart_upload?

      FileUtils.touch(File.join(ppath.path, 'content'))
      ppath.open('content', 'r+') do |f|
        f.seek from
        f.write content.to_s
      end

      ppath.open('.MULTIPART_UPLOAD', 'a') do |f|
        f.puts "#{from}-#{to}: #{hash}"
      end
    end

    ##
    # Archives are the same if the vault and id are the same
    def == other

      self.vault == other.vault && self.id == other.id

    end
  end
end