require 'pairtree'
module FakeGlacierEndpoint
  class Vault
    def self.create data_root, vault_name
      vault = Vault.new(data_root, vault_name)

      vault.create!

      vault
    end

    def self.list data_root
      return to_enum :list, data_root unless block_given?

      Dir.glob(File.join(data_root, '*')) do |f|
        yield f.gsub(data_root, '').gsub('/', '')
      end
    end

    def self.clear! data_root
      raise "!!!" unless defined?(:TEST_DATA_PATH) and data_root == TEST_DATA_PATH
      FileUtils.rm_rf(data_root)
    end

    attr_reader :data_root, :vault_name

    def initialize data_root, vault_name, options = {}
      @data_root = data_root
      @vault_name = vault_name
      @options = options
    end

    def exists?
      File.exists?(vault_path)
    end

    def delete
      true
    end

    def create!
      raise VaultAlreadyExistsException.new("That vault name is already taken") if exists?
      @pairtree ||= Pairtree.at(vault_path, :create => true)
    end

    def create_date
      File.ctime(vault_path)
    end

    def last_inventory_date
    end

    def count
      pairtree.list.length
    end

    def size
      0
    end

    def pairtree
      @pairtree ||= Pairtree.at(vault_path)
    end
    private

    def vault_path
      @vault_path ||= File.join(data_root, vault_name)
    end

    class VaultAlreadyExistsException < StandardError

    end
  end
end