require 'socket'
require 'securerandom'
require 'json'
require 'fileutils'
require 'cucumber/cli/main'
require 'observer'
require 'childprocess'
require_relative './abstract_listener'
require_relative './recording_vnc_listener'
require_relative './formatters/scenario_line_logger'
require_relative './formatters/junit_scenario_formatter'

module JCukeForker
  class Worker
    include Observable

    attr_reader :feature, :format, :out, :basename

    def initialize(status_path, task_path, recorder = nil)
      @status_path = status_path
      @task_path = task_path
      if ENV['DISPLAY'] && recorder
        config = JSON.parse(recorder)
        add_observer JCukeForker::RecordingVncListener.new(self, config)
      end
      @status_socket = TCPSocket.new 'localhost', status_path
      @status = nil
    end

    def register
      @worker_server = UNIXServer.new @task_path
      update_status :on_worker_register
    end

    def close
      @worker_server.close
      @status_socket.close
    end

    def run
      worker_socket = @worker_server.accept
      loop do
        raw_message = worker_socket.gets
        if raw_message.nil? then
          sleep 0.3
          next
        end
        if raw_message.strip == '__KILL__'
          update_status :on_worker_dead
          break
        end
        set_state raw_message
        update_status :on_task_starting, feature
        status = execute_cucumber
        update_status :on_task_finished, feature, status
      end
    end

    def update_status(meth, *args)
      message = [meth, @task_path]
      message += args

      changed
      notify_observers *message
      @status_socket.puts(message.to_json)
    end

    def failed?
      @status.nil? || !@status
    end

    def output(format = nil)
      format = @format if format.nil?
      File.join out, "#{basename}.#{format}"
    end

    def stdout
      File.join out, "#{basename}.stdout"
    end

    def stderr
      File.join out, "#{basename}.stderr"
    end

    def args
      args = Array(format).flat_map { |f| %W[--format #{f} --out #{output(f)}] }
      args += @extra_args
      args << feature
      args
    end

    private

    def set_state(raw_message)
      @status = nil
      json_obj = JSON.parse raw_message
      @format = json_obj['format']
      @feature = json_obj['feature']
      @extra_args = json_obj['extra_args']
      @out = json_obj['out']
      @basename = feature.gsub(/\W/, '_')
    end

    def execute_cucumber
      FileUtils.mkdir_p(out) unless File.exist? out

      $stdout.reopen stdout
      $stderr.reopen stderr

      begin
        Cucumber::Cli::Main.execute args
      rescue SystemExit => e
        @status = e.success?
      end

      $stdout.flush
      $stderr.flush

      @status
    end
  end
end
