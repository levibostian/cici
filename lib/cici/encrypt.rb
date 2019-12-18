# frozen_string_literal: true

require 'colorize'
require 'optparse'
require 'set'
require 'pathname'
require_relative './ui'
require_relative './util'
require_relative './constants'
require 'openssl'
require 'base64'

module CICI
  class Encrypt
    include CICI

    def initialize(ui, config)
      @ui = ui
      @config = config
      @util = CICI::Util.new(@ui)
    end

    def start
      assert_secret_files_exist
      compress
      assert_files_in_gitignore
      encrypt
    end

    private

    def assert_secret_files_exist
      @ui.verbose('Asserting secret files exist')

      assert_file_exists = lambda { |file|
        @ui.debug("Checking #{file} exists...")

        @ui.fail("File or directory at path #{file} does not exist. Can't encrypt your secrets with missing secrets.") unless File.exist?(file)
      }

      @ui.verbose("Checking secrets exist in #{@config.base_path} directory.")

      @config.all_secrets.each do |file|
        assert_file_exists.call(file)
      end
    end

    def compress
      @ui.verbose('Compressing secrets...')

      @util.run_command("tar cvf #{@config.output_file} #{@config.base_path}")
    end

    def encrypt
      @ui.verbose("Encrypting #{@config.output_file} to file #{@config.output_file_encrypted}")

      aes = OpenSSL::Cipher.new('AES-256-CBC')
      data = File.binread(@config.output_file)
      aes.encrypt
      key = aes.random_key
      iv = aes.random_iv
      File.write(@config.output_file_encrypted, aes.update(data) + aes.final)

      @ui.success('Success! Now, you need to follow these last few steps:')
      @ui.success("1. Make sure to add #{@config.output_file_encrypted} to your source code repository")
      @ui.success("2. Create a *secret* environment variable with key: #{CICI::DECRYPT_KEY_ENV_VAR} with value: #{Base64.encode64(key).strip}")
      @ui.success("3. Create a *secret* environment variable with key: #{CICI::DECRYPT_IV_ENV_VAR} with value: #{Base64.encode64(iv).strip}")
    end

    def assert_files_in_gitignore
      ignore_file_name = '.gitignore'

      if @config.skip_gitignore? || !File.exist?(ignore_file_name)
        @ui.verbose('Skipping adding entries to .gitignore file')
        return
      end

      @ui.verbose("Adding entries to #{ignore_file_name} file")

      current_gitignore_file_contents = Set[]
      File.foreach(ignore_file_name).with_index do |line, _line_num|
        line = line.strip
        current_gitignore_file_contents = current_gitignore_file_contents.add(line)
      end
      @ui.debug("current contents of #{ignore_file_name}: #{current_gitignore_file_contents}")

      new_gitignore_additions = current_gitignore_file_contents.clone
      add_to_gitignore = lambda { |file|
        new_gitignore_additions = new_gitignore_additions.add(file)
      }

      # Add all but the encrypted output file as that is required for decryption
      add_to_gitignore.call(@config.output_file)
      add_to_gitignore.call(@config.base_path)
      @config.all_secrets_original_paths.each do |secret_file|
        add_to_gitignore.call(secret_file)
      end

      new_gitignore_additions -= current_gitignore_file_contents
      @ui.debug("additions to #{ignore_file_name}: #{new_gitignore_additions}")

      new_gitignore_additions = new_gitignore_additions.to_a
      unless new_gitignore_additions.empty? # only write if something to add
        @ui.debug("writing new #{ignore_file_name} additions: #{new_gitignore_additions}")
        gitignore_file_prepended_additions = new_gitignore_additions.join("\n") + "\n\n" + File.read(ignore_file_name)

        File.write(ignore_file_name, gitignore_file_prepended_additions)
      end

      @ui.verbose("Done adding entries to #{ignore_file_name}")
    end
  end
end
