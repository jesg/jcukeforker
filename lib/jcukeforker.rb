unless RUBY_PLATFORM =~ /darwin|linux|java/
  raise "CukeForker only supported on *nix"
end


require "cucumber/cli/main"
require "vnctools"
require "fileutils"
require "observer"
require "forwardable"
require "ostruct"
require "json"
require "securerandom"
require "celluloid/io"
require "celluloid/autostart"

module JCukeForker
end

require 'jcukeforker/abstract_listener'
require 'jcukeforker/vnc_listener'
require 'jcukeforker/recording_vnc_listener'
require 'jcukeforker/logging_listener'
require 'jcukeforker/runner'
require 'jcukeforker/scenarios'
require 'jcukeforker/status_server'
require 'jcukeforker/task_manager'

require 'jcukeforker/formatters/scenario_line_logger'
require 'jcukeforker/formatters/junit_scenario_formatter'