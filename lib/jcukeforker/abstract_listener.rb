module JCukeForker
  class AbstractListener

    def on_run_starting
    end

    def on_worker_register(worker_path)
    end

    def on_worker_waiting(worker_path)
    end

    def on_worker_dead(worker_path)
    end

    def on_task_starting(worker_path, feature)
    end

    def on_task_finished(worker_path, feature, status)
    end

    def on_worker_forked(worker)
    end

    def on_worker_register(worker_path)
    end

    def on_worker_waiting(worker_path)
    end

    def on_worker_dead(worker_path)
    end

    def on_run_interrupted
    end

    def on_run_finished(failed)
    end

    def on_display_fetched(server)
    end

    def on_display_released(server)
    end

    def on_display_starting(server)
    end

    def on_display_stopping(server)
    end

    def on_eta(time, remaining, finished)
    end

    def update(meth, *args)
      __send__(meth, *args)
    end

  end # AbstractListener
end # CukeForker
