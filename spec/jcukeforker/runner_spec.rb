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

        mock_task_manager = double(TaskManager, :update => nil, :has_failures? => false)
        mock_status_server = double(StatusServer, :port => nil)
        mock_io_out = double(IO, :sync= => nil)
        mock_tasks = Array.new(2) { |n| double("Worker-#{n}") }

        expect(TaskManager).to receive(:new).with(features, mock_io_out, {format: format, out: out, extra_args: []}).and_return mock_task_manager
        expect(StatusServer).to receive(:new).with('/tmp/in').and_return mock_status_server
        expect(File).to receive(:open).with('/tmp/in', 'w').and_return mock_io_out
        expect(File).to receive(:open).with('/tmp/out', 'w').and_return mock_io_out
        expect(File).to receive(:open).with('/tmp/out', 'a').and_return mock_io_out

        expect(mock_status_server).to receive(:add_observer).with listeners.first
        expect(mock_status_server).to receive(:add_observer).with mock_task_manager

        expect(Runner.create(features,
          :max    => max,
          :notify => listeners,
          :format => format,
          :log    => false,
          :out    => out,
          :delay  => 1
        )).to be_kind_of(Runner)
      end

      it "creates and runs a new runner" do
        r = double(Runner)
        expect(Runner).to receive(:create).with(%w[a b], {}).and_return(r)
        expect(r).to receive(:run)

        Runner.run(%w[a b])
      end
    end

    context "running" do
      let(:listener) { double(AbstractListener, :update => nil) }
      let(:queue)    { double(Queue, :has_failures? => false) }
      let(:status_server) { double(StatusServer, :run => nil, :shutdown => nil) }
      let(:process) { double(ChildProcess, :start => nil, :wait => nil) }
      let(:work_dir) { '/tmp/jcukeforker-testdir' }
      let(:vnc_pool) { double(VncTools::ServerPool, :stop => nil) }
      let(:mock_task_manager) { double(TaskManager, :update => nil, :has_failures? => false) }
      let(:runner)   { Runner.new(status_server, [process], vnc_pool, 0, mock_task_manager) }


      it "processes the queue" do
        runner.add_observer listener

        expect(listener).to receive(:update).with(:on_run_starting)
        expect(process).to receive(:start)
        expect(process).to receive(:wait)

        runner.run
      end

      it "fires on_run_interrupted and shuts down if the run is interrupted" do
        runner.add_observer listener

        allow(process).to receive(:wait).and_raise(Interrupt)
        allow(runner).to receive(:stop)
        expect(listener).to receive(:update).with(:on_run_interrupted)

        runner.run
      end

      it "fires on_run_interrupted and shuts down if an error occurs" do
        runner.add_observer listener

        allow(process).to receive(:wait).and_raise(StandardError)
        allow(runner).to receive(:stop)

        expect{ runner.run }.to raise_error(StandardError)
      end
    end

  end # Runner
end # CukeForker
