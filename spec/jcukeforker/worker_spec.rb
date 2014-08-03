require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe Worker do
    let(:worker_path) { '/tmp/jcukeforker-test-socket' }
    let(:status_path) { '6333' }
    let(:mock_status_socket) { double(TCPSocket, :close => nil) }
    let(:mock_worker_server) { double(UNIXServer, :close => nil) }
    let(:mock_worker_socket) { double(UNIXSocket, :close => nil) }
    let(:worker) do
      TCPSocket.should_receive(:new).with('localhost', status_path).and_return(mock_status_socket)
      Worker.new status_path, worker_path
    end

    it "can create worker" do
      worker
    end

    it "can register worker" do
      UNIXServer.should_receive(:new).with(worker_path).and_return(mock_worker_server)

      mock_status_socket.should_receive(:puts).with("[\"on_worker_register\",\"/tmp/jcukeforker-test-socket\"]")

      worker.register
    end
  end
end
