require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe LoggingListener do
    let(:stdout)   { StringIO.new }
    let(:listener) { LoggingListener.new stdout }

    it "logs all events" do
      allow(Time).to receive(:now).and_return(Time.now)

      mock_worker = {:path => '1', :feature => 'foo/bar', :status => true }
      mock_worker2 = {:path => '15', :feature => 'foo/baz', :status => false}

      listener.on_run_starting
      listener.on_worker_register mock_worker[:path]
      listener.on_task_starting mock_worker[:path], mock_worker[:feature]
      listener.on_worker_register mock_worker2[:path]
      listener.on_task_starting mock_worker2[:path], mock_worker2[:feature]
      listener.on_task_finished mock_worker[:path], mock_worker[:feature], mock_worker[:status]
      listener.on_task_finished mock_worker2[:path], mock_worker2[:feature], mock_worker2[:failed?]
      listener.on_worker_dead mock_worker[:path]
      listener.on_worker_dead mock_worker2[:path]
      listener.on_run_interrupted
      listener.on_run_finished false

      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S##{Process.pid}")

      expect(stdout.string).to eql <<-OUTPUT
I, [#{timestamp}]  INFO -- : [    run           ] starting
I, [#{timestamp}]  INFO -- : [    worker  1     ] register: 1
I, [#{timestamp}]  INFO -- : [    worker  1     ] starting: foo/bar
I, [#{timestamp}]  INFO -- : [    worker  15    ] register: 15
I, [#{timestamp}]  INFO -- : [    worker  15    ] starting: foo/baz
I, [#{timestamp}]  INFO -- : [    worker  1     ] passed  : foo/bar
I, [#{timestamp}]  INFO -- : [    worker  15    ] failed  : foo/baz
I, [#{timestamp}]  INFO -- : [    worker  1     ] dead    : 1
I, [#{timestamp}]  INFO -- : [    worker  15    ] dead    : 15
I, [#{timestamp}]  INFO -- : [    run           ] interrupted - please wait
I, [#{timestamp}]  INFO -- : [    run           ] finished, passed
      OUTPUT
    end
  end # Worker
end # CukeForker
