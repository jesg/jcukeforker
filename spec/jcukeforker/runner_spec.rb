require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe Runner do

    context "creating" do
      it "sets up a new instance" do
        # sigh.

        max       = 4
        format    = :json
        out       = "/tmp"
        listeners = [double(AbstractListener, :update => nil)]
        log       = false
        features  = %w[a b]
        delay     = 1

        mock_task_manager = double(TaskManager, :update => nil)
        mock_status_server = double(StatusServer)
        mock_tasks = Array.new(2) { |n| double("Worker-#{n}") }

        TaskManager.should_receive(:new).with(features, {format: format, out: out, extra_args: []}).and_return mock_task_manager
        StatusServer.should_receive(:new).with('6333').and_return mock_status_server

        mock_status_server.should_receive(:add_observer).with listeners.first
        mock_status_server.should_receive(:add_observer).with mock_task_manager

        Runner.create(features,
          :max    => max,
          :notify => listeners,
          :format => format,
          :log    => false,
          :out    => out,
          :delay  => 1
        ).should be_kind_of(Runner)
      end

      it "creates and runs a new runner" do
        r = double(Runner)
        Runner.should_receive(:create).with(%w[a b], {}).and_return(r)
        r.should_receive(:run)

        Runner.run(%w[a b])
      end
    end

    context "running" do
      let(:listener) { double(AbstractListener, :update => nil) }
      let(:queue)    { double(Queue, :has_failures? => false) }
      let(:status_server0) { double(StatusServer, :run => nil) }
      let(:status_server) { double(StatusServer, :async => status_server0, :shutdown => nil) }
      let(:process) { double(ChildProcess, :start => nil, :wait => nil) }
      let(:work_dir) { '/tmp/jcukeforker-testdir' }
      let(:vnc_pool) { double(VncTools::ServerPool, :stop => nil) }
      let(:runner)   { Runner.new(status_server, [process], work_dir, vnc_pool, 0) }

      it "processes the queue" do
        runner.add_observer listener

        listener.should_receive(:update).with(:on_run_starting)
        process.should_receive(:start)
        process.should_receive(:wait)
#        listener.should_receive(:update).with(:on_run_finished, false)
        FileUtils.should_receive(:rm_r).with(work_dir)

        runner.run
      end

      it "fires on_run_interrupted and shuts down if the run is interrupted" do
        runner.add_observer listener

        process.stub(:wait).and_raise(Interrupt)
        runner.stub(:stop)
        listener.should_receive(:update).with(:on_run_interrupted)

        runner.run
      end

      it "fires on_run_interrupted and shuts down if an error occurs" do
        runner.add_observer listener

        process.stub(:wait).and_raise(StandardError)
        runner.stub(:stop)
        listener.should_receive(:update).with(:on_run_interrupted)

        lambda { runner.run }.should raise_error(StandardError)
      end
    end

  end # Runner
end # CukeForker
