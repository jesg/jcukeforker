require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe TaskManager do
    let(:worker_path) { '/tmp/jcukeforker-test-socket' }
    let(:feature) { 'feature:1' }
    let(:mock_socket) { double('socket', :puts => nil) }

    it "can register a worker" do

      UNIXSocket.stub(:open).and_return(mock_socket)
      expect(mock_socket).to receive(:puts).with({feature: feature}.to_json)

      task_manager = TaskManager.new [feature]
      task_manager.on_worker_register worker_path
    end

    it "can finish task" do

      expect(mock_socket).to receive(:puts).with({feature: feature}.to_json)

      task_manager = TaskManager.new [feature]
      task_manager.instance_variable_get(:@worker_sockets)[worker_path] = mock_socket
      task_manager.on_task_finished worker_path, nil, nil
    end

    it "can close dead worker" do

      expect(mock_socket).to receive(:close)

      task_manager = TaskManager.new [feature]
      task_manager.instance_variable_get(:@worker_sockets)[worker_path] = mock_socket
      task_manager.on_worker_dead worker_path
    end

    it "can send '__KILL__' when there are no tasks left" do

      expect(mock_socket).to receive(:puts).with('__KILL__')

      task_manager = TaskManager.new []
      task_manager.instance_variable_get(:@worker_sockets)[worker_path] = mock_socket
      task_manager.on_task_finished worker_path, nil, nil
    end

    it "can detect failure" do
      task_manager = TaskManager.new []
      def task_manager.pop_task(*args); end
      task_manager.on_task_finished worker_path, feature, false
      task_manager.has_failures?.should == true
    end
  end
end
