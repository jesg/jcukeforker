require "logger"

module JCukeForker
  class LoggingListener < AbstractListener
    TIME_FORMAT = "%Y-%m-%d %H:%M:%S"

    def initialize(io = STDOUT)
      @io = io
    end

    def on_run_starting
      log.info "[    run           ] starting"
    end

    def on_worker_register(worker_path)
      log.info "[    worker  #{worker_id(worker_path).ljust 3}   ] register: #{worker_path}"
    end

    def on_worker_dead(worker_path)
      log.info "[    worker  #{worker_id(worker_path).ljust 3}   ] dead    : #{worker_path}"
    end

    def on_task_starting(worker_path, feature)
      log.info "[    worker  #{worker_id(worker_path).ljust 3}   ] starting: #{feature}"
    end

    def on_task_finished(worker_path, feature, status)
      log.info "[    worker  #{worker_id(worker_path).ljust 3}   ] #{status_string(status).ljust(8)}: #{feature}"
    end

    def on_run_finished(failed)
      log.info "[    run           ] finished, #{status_string failed}"
    end

    def on_run_interrupted
      puts "\n"
      log.info "[    run           ] interrupted - please wait"
    end

    def on_display_fetched(server)
      log.info "[    display #{server.display.to_s.ljust(3)}   ] fetched"
    end

    def on_display_released(server)
      log.info "[    display #{server.display.to_s.ljust(3)}   ] released"
    end

    def on_display_starting(worker_path, display)
      log.info "[    display #{display.to_s.ljust(3)}   ] starting"
    end

    def on_display_stopping(worker_path, display)
      log.info "[    display #{display.to_s.ljust(3)}   ] stopping"
    end

    def on_eta(eta, remaining, finished)
      counts = "#{remaining}/#{finished}".ljust(6)
      log.info "[    eta     #{counts}] #{eta.strftime TIME_FORMAT}"
    end

    private

    def status_string(failed)
      failed == 'false' ? 'failed' : 'passed'
    end

    def worker_id(worker_path)
      /\-(\d+)$/.match(worker_path).captures[0]
    end

    def log
      @log ||= (
        log = Logger.new @io
        log.datetime_format = TIME_FORMAT

        log
      )
    end
  end # LoggingListener

end # CukeForker
