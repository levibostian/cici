# frozen_string_literal: true

require 'yaml'
require 'set'

module CICI
  class Config
    def initialize(ui)
      @ui = ui
    end

    def load
      config_file_name = '.cici.yml'

      @ui.fail("Cannot find config file, #{config_file_name} in current directory.") unless File.file?(config_file_name)

      config_file_contents = File.read(config_file_name)
      @config = YAML.safe_load(config_file_contents)

      @ui.verbose("Loaded config from file, #{config_file_name}")
      @ui.debug("Config: #{@config}")
    end

    # Functions below are to pull out parts from the config file

    # Get "path", or default value
    def base_path
      @config['path'] || 'secrets'
    end

    # Gets default array of secrets. Each secrets includes 'base_path' so they each look like:
    # "secrets/path_to_file/file.txt"
    def default_secrets
      default_secrets_without_base_path.map { |secret_path| Pathname.new(base_path).join(secret_path).to_s }
    end

    # Same as default_secrets(), but omit "base_path" inclusion. So you get raw entires from config file.
    def default_secrets_without_base_path
      secrets = []
      return secrets unless @config.key? 'default'

      return @config['default']['secrets'] if @config['default'].key? 'secrets'
    end

    # Get a Hash for the set from the config file
    def set(name)
      @ui.fail("Set, #{name}, does not exist in config file.") unless @config['sets'].key? name

      set = @config['sets'][name]

      set = {} if set.nil?

      set
    end

    # Gets the "base_path" for where all secrets will be stored for a set.
    # If set name is `production` and base path is `secrets/`, this function could return: "secrets/production/"
    def path_for_set(set_name)
      set = set(set_name)
      path = Pathname.new(base_path)

      directory = set.key?('path') ? set['path'] : set_name
      path = path.join(directory)

      path.to_s
    end

    # Same as secrets_for_set(), but omit "base_path" inclusion. So you get raw entires from config file.
    def secrets_for_set_without_base_path(set_name)
      set = set(set_name)
      return set['secrets'] if set.key? 'secrets'

      default_secrets_without_base_path
    end

    # Gets array of secrets for a set. Each secrets includes 'base_path' so they each look like:
    # "secrets/name-of-set/path_to_file/file.txt"
    def secrets_for_set(set_name)
      secrets_for_set_without_base_path(set_name).map { |secret_path| Pathname.new(path_for_set(set_name)).join(secret_path).to_s }
    end

    # Should skip gitignore operation?
    def skip_gitignore?
      skip = false
      return @config['skip_gitignore'] if @config.key? 'skip_gitignore'

      skip
    end

    # Get array of all secrets, including their base paths. So, a collection of files in the secrets directory to compress.
    def all_secrets
      secrets = Set[]
      secrets.merge(default_secrets)
      sets.keys.each { |set_key| secrets.merge(secrets_for_set(set_key)) }

      secrets.to_a
    end

    # Same as all_secrets(), but without base paths. So, a collection of files in their original source locations.
    def all_secrets_original_paths
      secrets = Set[]
      secrets.merge(default_secrets_without_base_path)
      sets.keys.each { |set_key| secrets.merge(secrets_for_set_without_base_path(set_key)) }

      secrets.to_a
    end

    # Hash of all sets
    def sets
      sets = {}
      sets = @config['sets'] if @config.key? 'sets'
      sets
    end

    # outout file name. Includes file extension
    def output_file
      output_file = 'secrets.tar'
      output_file = "#{@config['output']}.tar" unless @config['output'].nil?

      output_file
    end

    # output file name plus encryption file extension
    def output_file_encrypted
      "#{output_file}.enc"
    end
  end
end
