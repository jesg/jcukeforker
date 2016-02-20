
module JCukeForker
  class TaskManager < AbstractListener

    def initialize(features, opts={})
      @features = features
      @opts = opts
      @worker_sockets = {}
      @failures = false
      @mutex = Mutex.new
    end

    def on_worker_register(worker_path)
      @worker_sockets[worker_path] = UNIXSocket.open worker_path
      pop_task worker_path
    end

    def on_task_finished(worker_path, feature, status)
      @failures = @failures || !status
      pop_task worker_path
    end

    def on_worker_dead(worker_path)
     socket = @worker_sockets.delete worker_path
     socket.close
    end

    def close
      @worker_sockets.each {|k, v| v.close}
    end

    def has_failures?
      @failures
    end

    private

    def pop_task(worker_path)
        task = '__KILL__'
        @mutex.synchronize do
          if feature = @features.shift
            task = @opts.merge(feature: feature).to_json
          end
        end

      @worker_sockets[worker_path].puts(task)
    end
  end
end
