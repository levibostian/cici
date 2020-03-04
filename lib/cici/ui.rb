# frozen_string_literal: true

require 'colorize'
require 'optparse'

module CICI
  class UI
    def initialize(verbose, debug)
      @verbose = verbose
      @debug = debug
    end

    def success(message)
      puts message.colorize(:green)
    end

    def fail(message)
      abort(message.colorize(:red))
    end

    # No way to disable this. These are message that must be outputted.
    def message(message)
      puts message
    end

    def warning(message)
      puts message.to_s.colorize(:yellow)
    end

    def verbose(message)
      puts message.to_s if @verbose
    end

    def debug(message)
      puts message.to_s.colorize(:light_blue) if @debug
    end
  end
end
