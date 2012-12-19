require 'pairtree'
require 'fileutils'
require 'dbm'

module Icemelt
  class Vault
    def self.create data_root, vault_name
      vault = Vault.new(data_root, vault_name)

      vault.create!

      vault
    end

    def self.find *args
      vault = Vault.new(*args)

      raise "" unless vault.exists?

      vault
    end

    def self.list data_root
      return to_enum :list, data_root unless block_given?

      Dir.glob(File.join(data_root, '*')) do |f|
      	next unless File.directory?(f) and File.exists?(File.join(f, 'pairtree_root'))
        yield Vault.new(data_root, f.gsub(data_root, '').gsub('/', ''))
      end
    end

    def self.clear! data_root
      raise "THIS METHOD SHOULD ONLY BE CALLED IN TESTS" unless defined?(:TEST_DATA_PATH) and data_root == TEST_DATA_PATH
      FileUtils.rm_r(data_root, :force => true)
    end

    attr_reader :data_root, :vault_name

    def initialize data_root, vault_name, options = {}
      @data_root = data_root
      @vault_name = vault_name
      @options = options
    end

    def id
      vault_name
    end

    def exists?
      File.exists?(vault_path)
    end

    def delete
      FileUtils.rm_r vault_path, :force => true
    end

    def create!
      @pairtree ||= Pairtree.at(vault_path, :create => true)
    end

    def create_date
      File.ctime(vault_path)
    end

    def last_inventory_date
      File.ctime(vault_path)
    end

    def count
      pairtree.list.length
    end

    def size
      size = 0
      archives { |a| size += a.size }
      size
    end

    def pairtree
      @pairtree ||= Pairtree.at(vault_path)
    end

    def jobs
      dbm.map { |k,v| job(k.to_i) }
    end

    def job id
      Job.new(self, id, Marshal.load(dbm[id.to_s]))
    end

    def archives
      return to_enum :archives unless block_given?

      pairtree.list.map { |x| yield Archive.new(self, x) }
    end

    def archive id
      Archive.new(self, id)
    end

    def add_job job
      dbm.store(job.id.to_s, Marshal.dump(job.options))
      dbm.close
      @dbm = nil
    end

    def aws_attributes
{'CreationDate' => create_date,
        'LastInventoryDate' => last_inventory_date,
        'NumberOfArchives' => count,
        'SizeInBytes' => size,
        'VaultARN' => arn,
        'VaultName' => id }
    end

 
    def arn
      "arn:fake:glacier:localhost:012345678901:vaults/#{id.to_s}"
    end
    private
    def dbm
      @dbm ||= DBM.open(File.join(vault_path, 'jobs'))
    end

    def vault_path
      @vault_path ||= File.join(data_root, vault_name)
    end
  end
end