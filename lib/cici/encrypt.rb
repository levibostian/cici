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

    def initialize(ui, decrypter, config)
      @ui = ui
      @config = config
      @util = CICI::Util.new(@ui)
      @decrypter = decrypter

      # Default key/iv that's generated for you. We can change these values later before encryption. 
      aes = OpenSSL::Cipher.new('AES-256-CBC')      
      aes.encrypt
      @encryption_key = aes.random_key
      @encryption_iv = aes.random_iv
      @first_time_encrypting = false
    end

    def start
      assert_secret_files_exist
      # We want to reuse key/iv values for encryption. So, let's get those values before moving forward. 
      prompt_for_keys
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

    def prompt_for_keys
      has_encrypted_before = File.exist?(@config.output_file)

      if has_encrypted_before 
        @ui.message("It looks like you have encrypted your secrets before.")
        @ui.message("Enter the key you use to encrypt:")
        key = Base64.decode64(STDIN.gets.chomp)
        @ui.message("Enter the IV you use to encrypt:")
        iv = Base64.decode64(STDIN.gets.chomp)

        plain = @decrypter.decrypt(key, iv)
        if plain.empty?
          @ui.fail("Key or IV value does not match the key/IV pair used when previously encrypting")
        end

        @encryption_key = key 
        @encryption_iv = iv 
      else 
        @ui.debug("Encrypted output file, #{@config.output_file}, does not exist. Therefore, let's assume this is the first time encrypting secrets.")

        @ui.message("It looks like this is the first time that you are encrypting secrets.")
        @ui.message("Generating secure keys for you...")        
        @first_time_encrypting = true
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
      aes.key = @encryption_key
      aes.iv = @encryption_iv
      File.write(@config.output_file_encrypted, aes.update(data) + aes.final)

      if @first_time_encrypting 
        @ui.success('Success! Now, you need to follow these last few steps:')
        @ui.success("1. Make sure to add #{@config.output_file_encrypted} to your version control")
        @ui.success("Below you will find secret keys used to encrypt and decrypt your secrets in the future. These will not be revealed ever again. Store these in a safe and secure place.")
        @ui.success("2. Share these secret keys with your team because they must provide the same keys in the future to encrypt values again. Setup cici encrypt in a git hook if you wish to always make sure secrets are up-to-date.")
        @ui.success("3. Set these *secret* environment variables in your CI server for decryption.")
        @ui.success("Key: #{CICI::DECRYPT_KEY_ENV_VAR} and value: #{Base64.encode64(@encryption_key).strip}")
        @ui.success("Key: #{CICI::DECRYPT_IV_ENV_VAR} and value: #{Base64.encode64(@encryption_iv).strip}")
      else 
        @ui.success("Success!")
      end       
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
