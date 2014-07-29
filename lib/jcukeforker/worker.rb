require 'socket'
require 'securerandom'
require 'json'
require 'vnctools'
require 'observer'
require 'childprocess'
require_relative './configurable_vnc_server'
require_relative './abstract_listener'
require_relative './vnc_listener'
require_relative './recording_vnc_listener'

module JCukeForker
  class Worker
    include Observable

    attr_reader :feature, :format, :out

    def initialize(status_path, task_path, vnc = nil, recorder = nil)
      @status_path = status_path
      @task_path = task_path
      if vnc
        vnc_config = JSON.parse(vnc)
        vnc_listener = JCukeForker::VncListener.new(self, vnc_config)
        add_observer vnc_listener
        if recorder
          config = JSON.parse(recorder)
          config[:geometry] = vnc_config[:geometry] || ConfigurableVncServer::DEFAULT_OPTIONS[:geometry]
          add_observer JCukeForker::RecordingVncListener.new(self, config)
        end
      end
      @status_socket = TCPSocket.new 'localhost', status_path
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

    def output
      File.join out, "#{basename}.#{format}"
    end

    def stdout
      File.join out, "#{basename}.stdout"
    end

    def stderr
      File.join out, "#{basename}.stderr"
    end

    def basename
      @basename ||= feature.gsub(/\W/, '_')
    end

    def args
      args = %W[--format #{format} --out #{output}]
      args += @extra_args
      args << feature

      args
    end

    private

    def set_state(raw_message)
      json_obj = JSON.parse raw_message
      @format = json_obj['format']
      @feature = json_obj['feature']
      @extra_args = json_obj['extra_args']
      @out = json_obj['out']
    end

    def execute_cucumber
      FileUtils.mkdir_p(out) unless File.exist? out

      $stdout.reopen stdout
      $stderr.reopen stderr

      failed = Cucumber::Cli::Main.execute args

      $stdout.flush
      $stderr.flush

      failed
    end
  end
end
