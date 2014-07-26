module JCukeForker

  #
  # Runner.run(features, opts)
  #
  # where 'features' is an Array of file:line
  # and 'opts' is a Hash of options:
  #
  #   :max        => Fixnum            number of workers (default: 2, pass 0 for unlimited)
  #   :vnc        => true/false,Class  children are launched with DISPLAY set from a VNC server pool,
  #                                    where the size of the pool is equal to :max. If passed a Class instance,
  #                                    this will be passed as the second argument to VncTools::ServerPool.
  #   :record     => true/false,Hash   whether to record a video of failed tests (requires ffmpeg)
  #                                    this will be ignored if if :vnc is not true. If passed a Hash,
  #                                    this will be passed as options to RecordingVncListener
  #   :notify     => object            (or array of objects) implementing the AbstractListener API
  #   :out        => path              directory to dump output to (default: current working dir)
  #   :log        => true/false        wether or not to log to stdout (default: true)
  #   :format     => Symbol            format passed to `cucumber --format` (default: html)
  #   :extra_args => Array             extra arguments passed to cucumber
  #   :delay      => Numeric           seconds to sleep between each worker is started (default: 0)
  #

  class Runner
    include Observable

    DEFAULT_OPTIONS = {
      :max    => 2,
      :vnc    => false,
      :record => false,
      :notify => nil,
      :out    => Dir.pwd,
      :log    => true,
      :format => :html,
      :delay  => 0
    }

    def self.run(features, opts = {})
      create(features, opts).run
    end

    def self.create(features, opts = {})
      opts = DEFAULT_OPTIONS.dup.merge(opts)

      max        = opts[:max]
      format     = opts[:format]
      out        = File.join opts[:out]
      listeners  = Array(opts[:notify])
      extra_args = Array(opts[:extra_args])
      delay      = opts[:delay]

      if opts[:log]
        listeners << LoggingListener.new
      end

      task_manager = TaskManager.new
      features.each do |feature|
        task_manager.add({feature: feature, format: format,out: out,extra_args: extra_args})
      end

      listeners << task_manager
      status_server = StatusServer.new '6333'
      worker_dir = "/tmp/jcukeforker-#{SecureRandom.hex 4}"
      FileUtils.mkdir_p worker_dir
      processes = create_processes(max, '6333', worker_dir, opts[:vnc], opts[:record])

      runner = Runner.new status_server, processes, worker_dir

      listeners.each { |l|
        status_server.add_observer l
        runner.add_observer l
      }

      runner
    end

    def initialize(status_server, processes, worker_dir)
      @status_server = status_server
      @processes = processes
      @worker_dir = worker_dir
    end

    def run
      start
      process
      stop
    rescue Interrupt
      fire :on_run_interrupted
      stop
    rescue StandardError
      fire :on_run_interrupted
      stop
      raise
    end

    private

    def self.create_processes(max, status_path, worker_dir, vnc = false, record = false)
      worker_file = "#{File.expand_path File.dirname(__FILE__)}/worker.rb"

      (1..max).inject([]) do |l, i|
        process_args = %W[ruby #{worker_file} #{status_path} #{worker_dir}/worker-#{i}]
        if vnc
          vnc = {} unless vnc.is_a? Hash
          record = {} unless record.is_a? Hash
          process_args << vnc.to_json
          process_args << record.to_json if record
        end
        process = ChildProcess.build(*process_args)
        l << process
      end
    end

    def start
      @status_server.async.run
      fire :on_run_starting

      @processes.each do |process|
        process.start
        sleep 0.3  #  ease vnc race condition
      end
    end

    def process
      @processes.each &:wait
    end

    def stop
      @status_server.shutdown
    ensure # catch potential second Interrupt
      FileUtils.rm_r @worker_dir
      #fire :on_run_finished, @queue.has_failures?
    end

    def fire(*args)
      changed
      notify_observers(*args)
    end

  end # Runner
end # CukeForker
