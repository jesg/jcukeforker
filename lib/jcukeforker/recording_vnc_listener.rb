
module JCukeForker
  class RecordingVncListener < AbstractListener

    def initialize(worker, opts = {})
      @ext      = opts[:codec] || "webm"
      @options  = opts
      @worker = worker

      @recorder = nil
    end

    def on_task_starting(worker_path, feature)

      @recorder = recorder_for(feature)
      @recorder.start
    end

    def on_task_finished(worker, feature, status)
      if @recorder.crashed?
        raise 'ffmpeg failed'
      end

      @recorder.stop

      @recorder = nil
    end

    def on_worker_dead(worker_path)
      @recorder && @recorder.stop
    end

    private

    def recorder_for(feature)
      output  = File.join(@worker.out, "#{feature.gsub(/\W/, '_')}.#{@ext}")

      process = ChildProcess.build(
        'ffmpeg',
        '-an',
        '-y',
        '-f', 'x11grab',
        '-r', @options[:frame_rate] || '5',
        '-s', @options[:geometry] || '1024x768',
        '-i', ENV['DISPLAY'],
        '-vcodec', @options[:codec] || 'vp8',
        output
      )
      process.io.stdout = process.io.stderr = File.open('/dev/null', 'w')
      process
    end

  end # RecordingVncListener
end # CukeForker
