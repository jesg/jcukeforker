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

        TaskManager.should_receive(:new).and_return mock_task_manager
        StatusServer.should_receive(:new).with('6333').and_return mock_status_server

        mock_status_server.should_receive(:add_observer).with listeners.first
        mock_status_server.should_receive(:add_observer).with mock_task_manager

        mock_task_manager.should_receive(:add).with(feature: features[0], format: format, out: out, extra_args: [])
        mock_task_manager.should_receive(:add).with(feature: features[1], format: format, out: out, extra_args: [])

        Runner.create(features,
          :max    => max,
          :notify => listeners,
          :format => format,
          :log    => false,
          :out    => out,
          :delay  => 1
        ).should be_kind_of(Runner)
      end

#      it "sets up the VNC pool if :vnc => true" do
#        mock_pool = double(VncTools::ServerPool, :add_observer => nil)
#        VncTools::ServerPool.should_receive(:new).with(2).and_return mock_pool
#        VncListener.should_receive(:new).with(mock_pool).and_return double(:update => nil)
#
#        Runner.create([], :max => 2, :vnc => true)
#      end
#
#      it "sets up the VNC pool with a custom server class" do
#        server_class = Class.new
#
#        mock_pool = double(VncTools::ServerPool, :add_observer => nil)
#        VncTools::ServerPool.should_receive(:new).with(2, server_class).and_return mock_pool
#        VncListener.should_receive(:new).with(mock_pool).and_return double(:update => nil)
#
#        Runner.create([], :max => 2, :vnc => server_class)
#      end
#
#      it "sets up VNC recording if :record => true" do
#        mock_pool = double(VncTools::ServerPool, :add_observer => nil)
#        VncTools::ServerPool.should_receive(:new).with(2).and_return mock_pool
#
#        mock_vnc_listener = double(:update => nil)
#        VncListener.should_receive(:new).with(mock_pool).and_return(mock_vnc_listener)
#        RecordingVncListener.should_receive(:new).with(mock_vnc_listener).and_return(double(:update => nil))
#
#        Runner.create([], :max => 2, :vnc => true, :record => true)
#      end
#
#      it "sets up VNC recording if :record => Hash" do
#        mock_pool = double(VncTools::ServerPool, :add_observer => nil)
#        VncTools::ServerPool.should_receive(:new).with(2).and_return mock_pool
#
#        mock_vnc_listener = double(:update => nil)
#        VncListener.should_receive(:new).with(mock_pool).and_return(mock_vnc_listener)
#        RecordingVncListener.should_receive(:new).with(mock_vnc_listener, :codec => "flv").and_return(double(:update => nil))
#
#        Runner.create([], :max => 2, :vnc => true, :record => {:codec => "flv"})
#      end

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
      let(:runner)   { Runner.new(status_server, [process], work_dir) }

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
