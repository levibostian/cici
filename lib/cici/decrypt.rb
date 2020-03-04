# frozen_string_literal: true

require 'colorize'
require 'optparse'
require 'set'
require 'pathname'
require_relative './ui'
require_relative './util'
require_relative './constants'
require 'base64'
require 'openssl'
require 'fileutils'

module CICI
  class Decrypt
    include CICI

    def initialize(ui, config)
      @ui = ui
      @config = config
      @util = CICI::Util.new(@ui)
    end

    def start(set)
      @set = set

      assert_encrypted_secret_exist
      plain = decrypt(Base64.decode64(@util.get_env(CICI::DECRYPT_KEY_ENV_VAR)), Base64.decode64(@util.get_env(CICI::DECRYPT_IV_ENV_VAR)))
      if !plain.empty?
        File.write(@config.output_file, plain)
      else
        @ui.fail('Wrong key/iv pair for decryption.')
      end
      decompress
      copy_files

      @ui.success('Files successfully decrypted and copied to their destination!')
    end

    def decrypt(key, iv)
      @ui.verbose('Decrypting secrets encrypted file.')

      decipher = OpenSSL::Cipher.new('AES-256-CBC')
      decipher.decrypt
      decipher.key = key
      decipher.iv = iv

      plain = decipher.update(File.read(@config.output_file_encrypted)) + decipher.final

      plain
    end

    private

    def assert_encrypted_secret_exist
      @ui.fail("Encrypted secrets file, #{@config.output_file_encrypted}, does not exist") unless File.file?(@config.output_file_encrypted)
    end

    def decompress
      @ui.verbose('Decompressing compressed file.')

      @util.run_command("tar xvf #{@config.output_file}")
    end

    def copy_files
      @ui.verbose('Copying files to their final destination')

      copy_file = lambda { |path, secrets_path|
        source = Pathname.new(secrets_path).join(path).to_s
        destination = path

        @ui.verbose("Copying file from #{source} to #{destination}")

        parent_directory = Pathname.new(destination).expand_path.dirname.to_s

        @ui.debug("mkdir -p for: #{parent_directory}")
        FileUtils.mkdir_p(parent_directory)
        @ui.debug("cp -r for, source: #{source}, destination: #{destination}")
        FileUtils.cp_r(source, destination)
      }

      if @set.nil?
        @config.default_secrets_without_base_path.each do |secret|
          copy_file.call(secret, @config.base_path)
        end
      else
        @config.secrets_for_set_without_base_path(@set).each do |secret|
          copy_file.call(secret, @config.path_for_set(@set))
        end
      end
    end
  end
end
