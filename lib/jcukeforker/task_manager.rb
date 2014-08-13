
module JCukeForker
  class TaskManager < AbstractListener

    def initialize(features, opts={})
      @features = features
      @opts = opts
      @worker_sockets = {}
    end

    def on_worker_register(worker_path)
      @worker_sockets[worker_path] = UNIXSocket.open worker_path
      pop_task worker_path
    end

    def on_task_finished(worker_path, feature, status)
      pop_task worker_path
    end

    def on_worker_dead(worker_path)
     socket = @worker_sockets.delete worker_path
     socket.close
    end

    def close
      @worker_sockets.each {|k, v| v.close}
    end

    private

    def pop_task(worker_path)
      task = '__KILL__'
      if feature = @features.shift
        task = @opts.merge(feature: feature).to_json
      end

      @worker_sockets[worker_path].puts(task)
    end
  end
end
