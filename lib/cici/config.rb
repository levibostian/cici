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

    def base_path
      @config['path'] || 'secrets'
    end

    def default_secrets
      default_secrets_without_base_path.map { |secret_path| Pathname.new(base_path).join(secret_path).to_s }
    end

    def default_secrets_without_base_path
      secrets = []
      secrets = @config['default']['secrets'] if @config['default'].key? 'secrets'

      secrets
    end

    def set(name)
      @ui.fail("Set, #{name}, does not exist in config file.") unless @config['sets'].key? name

      @config['sets'][name]
    end

    def path_for_set(set_name)
      set = set(set_name)
      path = Pathname.new(base_path)

      directory = set.key?('path') ? set['path'] : set_name
      path = path.join(directory)

      path.to_s
    end

    def secrets_for_set_without_base_path(set_name)
      set = set(set_name)
      return set['secrets'] if set.key? 'secrets'

      default_secrets_without_base_path
    end

    def secrets_for_set(set_name)
      secrets_for_set_without_base_path(set_name).map { |secret_path| Pathname.new(path_for_set(set_name)).join(secret_path).to_s }
    end

    def skip_gitignore
      skip = false
      return @config['skip_gitignore'] if @config.key? 'skip_gitignore'

      skip
    end

    def all_secrets
      secrets = Set[]
      secrets.merge(default_secrets)
      sets.keys.each { |set_key| secrets.merge(secrets_for_set(set_key)) }

      secrets.to_a
    end

    # from default and sets, gets all paths.
    def all_secrets_original_paths
      secrets = Set[]
      secrets.merge(default_secrets_without_base_path)
      sets.keys.each { |set_key| secrets.merge(secrets_for_set_without_base_path(set_key)) }

      secrets.to_a
    end

    def sets
      @config['sets']
    end

    def output_file
      output_file = 'secrets.tar'
      output_file = "#{@config['output']}.tar" unless @config['output'].nil?

      output_file
    end

    def output_file_encrypted
      "#{output_file}.enc"
    end
  end
end
