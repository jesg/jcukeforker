require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe Worker do
    let(:worker_path) { '/tmp/jcukeforker-test-socket' }
    let(:status_path) { '/tmp/in' }
    let(:mock_status_file) { double(IO, :close => nil) }
    let(:mock_worker_server) { double(UNIXServer, :close => nil) }
    let(:mock_worker_socket) { double(UNIXSocket, :close => nil) }
    let(:worker) do
      File.should_receive(:open).with('/tmp/in', 'a').and_return(mock_status_file)
      mock_status_file.should_receive(:sync=).with(true)
      Worker.new status_path, worker_path, '1'
    end

    it "can create worker" do
      worker
    end

    it "can register worker" do

      mock_status_file.should_receive(:write).with("[\"on_worker_register\",\"1\"]#{$-0}")
      mock_event_file = double(IO)
      File.should_receive(:open).with(worker_path, 'r').and_return(mock_event_file)

      worker.register
    end

    context "running a scenario with multiple report formats" do
      formats = [ :json, :junit ]
      path = "some/path"

      it "has an output file for each format specified" do
        json_str = {'format' => formats, 'feature' => 'some/feature:51', 'extra_args' => [], 'out' => path}
        worker.send :set_state, json_str
        expected_args = formats.flat_map do |f|
          %W[--format #{f} --out #{path}/some_feature_51.#{f}]
        end
        worker.args.each_cons(expected_args.size).include?(expected_args).should be true
      end
    end
  end
end
