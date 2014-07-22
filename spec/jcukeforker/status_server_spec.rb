require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe StatusServer do
    it "initializes at designated port" do
      mock_tcp_server = double(TCPServer).as_null_object

      TCPServer.should_receive(:new).with('localhost', '4444').and_return mock_tcp_server

      StatusServer.new '4444'
    end

    it "can handle a connection" do

      status = :on_worker_register
      worker_path = 'worker-path'
      raw_message = [status, worker_path].to_json

      # register a listener, just do an end to end test
      mock_listener = double(AbstractListener, :update => nil)
      mock_listener.should_receive(:update).with(status.to_s, worker_path)

      # expect the worker to register
      status_server = StatusServer.new
      status_server.add_observer mock_listener

      socket = TCPSocket.new 'localhost', '6333'
      socket.puts raw_message
      socket.close

      status_server.handle_connection( status_server.instance_variable_get(:@server).accept )

      status_server.shutdown
   end
  end
end
