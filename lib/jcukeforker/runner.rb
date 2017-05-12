module JCukeForker

  #
  # Runner.run(features, opts)
  #
  # where 'features' is an Array of file:line
  # and 'opts' is a Hash of options:
  #
  #   :max        => Fixnum            number of workers (default: 2, pass 0 for unlimited)
  #   :vnc        => true/false,Class,Array  children are launched with DISPLAY set from a VNC server pool,
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
      :delay  => 0,
    }

    def self.run(features, opts = {})
      create(features, opts).run
    end

    def self.create(features, opts = {})
      opts = DEFAULT_OPTIONS.dup.merge(opts)

      max        = opts[:max]
      raise ':max must be >= 1' if max < 1
      format     = opts[:format]
      out        = File.expand_path(File.join(opts[:out]))
      listeners  = Array(opts[:notify])
      extra_args = Array(opts[:extra_args])
      delay      = opts[:delay]
      puts "The port option is deprecated in jcukeforker > 0.2.10" if opts[:port]

      if opts[:log]
        listeners << LoggingListener.new
      end

      FileUtils.mkdir_p out
      io_in = File.join out, 'in'
      io_out = File.join out, 'out'
      # truncate
      File.open(io_in, 'w') {}
      File.open(io_out, 'w') {}

      task_opts = {format: format,out: out,extra_args: extra_args}
      io_out_file = File.open(io_out, 'a')
      io_out_file.sync = true
      task_manager = TaskManager.new features, io_out_file, task_opts

      listeners << task_manager
      status_server = StatusServer.new io_in

      vnc_pool = nil
      if vnc = opts[:vnc]
       if vnc.kind_of?(Array)
         vnc_pool = VncTools::ServerPool.new(max, ConfigurableVncServer.create_class(vnc))
       elsif vnc.kind_of?(Class)
         vnc_pool = VncTools::ServerPool.new(max, vnc)
       else
         vnc_pool = VncTools::ServerPool.new(max)
       end
      end

      processes = create_processes(max, io_in, io_out, vnc_pool, opts[:record])

      runner = Runner.new status_server, processes, vnc_pool, delay, task_manager

      listeners.each { |l|
        status_server.add_observer l
        runner.add_observer l
      }

      runner
    end

    def initialize(status_server, processes, vnc_pool, delay, task_manager)
      @status_server = status_server
      @processes = processes
      @vnc_pool = vnc_pool
      @delay = delay
      @task_manager = task_manager
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

    def self.create_processes(max, io_in, io_out, vnc_pool = nil, record = false)
      worker_file = "#{File.expand_path File.dirname(__FILE__)}/worker_script.rb"

      (1..max).inject([]) do |l, i|
        process_args = %W[ruby #{worker_file} #{io_in} #{io_out} #{i}]
        if vnc_pool && record
          if record.kind_of? Hash
            process_args << record.to_json
          else
            process_args << {}.to_json
          end
        end
        process = ChildProcess.build(*process_args)
        process.io.inherit!
        process.environment['DISPLAY'] = vnc_pool.get.display if vnc_pool
        process.environment['JCUKEFORKER_WORKER'] = i
        l << process
      end
    end

    def start
      @status_server.run
      fire :on_run_starting

      @processes.each do |process|
        process.start
        sleep @delay
      end
    end

    def process
      @processes.each &:wait
    end

    def stop
      @status_server.shutdown
    ensure # catch potential second Interrupt
      @vnc_pool.stop if @vnc_pool
      fire :on_run_finished, @task_manager.has_failures?
    end

    def fire(*args)
      changed
      notify_observers(*args)
    end

  end # Runner
end # CukeForker
