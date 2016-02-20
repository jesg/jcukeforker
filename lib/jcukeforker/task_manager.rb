
module JCukeForker
  class TaskManager < AbstractListener

    def initialize(features, io_out, opts={})
      @features = features
      @opts = opts
      @io_out = io_out
      @failures = false
    end

    def on_worker_register(worker_path)
      pop_task worker_path
    end

    def on_task_finished(worker_path, feature, status)
      @failures = @failures || !status
      pop_task worker_path
    end

    def close
      io_out.close
    end

    def has_failures?
      @failures
    end

    private

    def pop_task(worker_path)
      task = {action: '__KILL__', worker: worker_path}.to_json
      if feature = @features.shift
        task = @opts.merge(worker: worker_path, feature: feature, action: :feature).to_json
      end

      @io_out.write("#{task}#{$-0}")
    end
  end
end
