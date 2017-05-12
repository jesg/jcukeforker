require 'securerandom'
require 'json'
require 'fileutils'
require 'cucumber/cli/main'
require 'observer'
require 'childprocess'
require_relative './abstract_listener'
require_relative './recording_vnc_listener'
require_relative './formatters/junit_scenario_formatter'

module JCukeForker
  class Worker
    include Observable

    attr_reader :feature, :format, :out, :basename

    def initialize(status_path, task_path, worker_num, recorder = nil)
      @status_path = status_path
      @task_path = task_path
      @worker_num = worker_num
      if ENV['DISPLAY'] && recorder
        config = JSON.parse(recorder)
        add_observer JCukeForker::RecordingVncListener.new(self, config)
      end
      @status_file = File.open(status_path, 'a')
      @status_file.sync = true
      @status = nil
    end

    def register
      @event_file = File.open(@task_path, 'r')
      update_status :on_worker_register
    end

    def close
      @event_file.close
      @status_file.close
    end

    def run
      loop do
        raw_message = @event_file.gets(sep=$-0)
        if raw_message.nil? then
          sleep 0.1
          next
        end
        json_obj = JSON.parse raw_message
        next unless json_obj['worker'] == @worker_num
        if json_obj['action'] == '__KILL__'
          update_status :on_worker_dead
          break
        end
        set_state json_obj
        update_status :on_task_starting, feature
        status = execute_cucumber
        update_status :on_task_finished, feature, status
      end
    end

    def update_status(meth, *args)
      message = [meth, @worker_num]

      message += args

      changed
      notify_observers *message
      @status_file.write("#{message.to_json}#{$-0}")
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

    def set_state(json_obj)
      @status = nil
      @format = json_obj['format']
      @feature = json_obj['feature']
      @extra_args = json_obj['extra_args']
      @out = json_obj['out']
      @basename = feature.gsub(/\W/, '_')
    end

    def execute_cucumber
      FileUtils.mkdir_p(out) unless File.exist? out

      STDOUT.reopen stdout, 'a'
      STDERR.reopen stderr, 'a'

      begin
        Cucumber::Cli::Main.execute args
      rescue SystemExit => e
        @status = e.success?
      end

      STDOUT.flush
      STDERR.flush

      @status
    end
  end
end
