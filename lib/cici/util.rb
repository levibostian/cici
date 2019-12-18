# frozen_string_literal: true

module CICI
  class Util
    def initialize(ui)
      @ui = ui
    end

    def run_command(command)
      @ui.warning("Running command: #{command}")
      success = system(command)
      @ui.fail("\nCommand failed. Fix issue and try again.") unless success
    end

    def get_env(name)
      @ui.fail("Forgot to specify environment variable, #{name}") unless ENV[name]
      ENV[name]
    end
  end
end
