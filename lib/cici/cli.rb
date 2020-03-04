# frozen_string_literal: true

require 'colorize'
require 'optparse'
require 'set'
require 'pathname'
require_relative './ui'
require_relative './util'
require_relative './encrypt'
require_relative './decrypt'
require_relative './version'
require_relative './config'

module CICI
  Options = Struct.new(:verbose, :debug, :help, :set)

  class CLI
    def initialize
      @options = parse_options

      @ui = CICI::UI.new(@options.verbose, @options.debug)
      @ui.debug("Options: #{@options}")

      @config = CICI::Config.new(@ui)
      @config.load

      @decrypter = CICI::Decrypt.new(@ui, @config)
      @encrypter = CICI::Encrypt.new(@ui, @decrypter, @config)      

      run_command
    end

    def run_command
      case ARGV[0]
      when 'encrypt'
        encrypt
      when 'decrypt'
        decrypt
      else
        @ui.fail('Command invalid.')
        print_help(1)
      end
    end

    def print_help(exit_code)
      puts @options.help
      exit exit_code
    end

    def parse_options
      options = Options.new
      options.verbose = false
      options.debug = false

      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: cici encrypt|decrypt [options]'

        opts.on('-v', '--version', 'Print version') do
          puts CICI::Version.get
          exit
        end
        opts.on('--verbose', 'Verbose output') do
          options.verbose = true
        end
        opts.on('--debug', 'Debug output (also turns on verbose)') do
          options.verbose = true
          options.debug = true
        end
        opts.on('--set SET_NAME', 'Set to decrypt (Note: option ignored for encrypt command)') do |set_name|
          options.set = set_name
        end
        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end

      help = opt_parser.help
      options.help = help
      abort(help) if ARGV.empty?

      opt_parser.parse!(ARGV)

      options
    end

    def encrypt
      @encrypter.start
    end

    def decrypt
      @decrypter.start(@options.set)
    end
  end
end
