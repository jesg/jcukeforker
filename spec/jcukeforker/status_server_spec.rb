require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe StatusServer do

    it "can handle a message" do

      status = :on_worker_register
      worker_path = 'worker-path'
      raw_message = [status, worker_path].to_json

      # register a listener, just do an end to end test
      mock_listener = double(AbstractListener, :update => nil)
      expect(mock_listener).to receive(:update).with(status.to_s, worker_path)
			mock_io = double(IO, :sync= => nil)
			expect(File).to receive(:open).with('/tmp/in', 'r').and_return(mock_io)

      # expect the worker to register
      io_in = '/tmp/in'
      status_server = StatusServer.new io_in
      status_server.add_observer mock_listener

      status_server.handle_message(raw_message)

   end
  end
end
