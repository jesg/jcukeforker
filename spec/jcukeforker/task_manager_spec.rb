require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe TaskManager do
    let(:worker_path) { '/tmp/jcukeforker-test-socket' }
    let(:task) { {name: 'my task'} }
    let(:mock_socket) { double('socket', :puts => nil) }

    it "can register a worker" do

      UNIXSocket.stub(:open).and_return(mock_socket)
      expect(mock_socket).to receive(:puts).with(task.to_json)

      task_manager = TaskManager.new
      task_manager.add task
      task_manager.on_worker_register worker_path
    end

    it "can finish task" do

      expect(mock_socket).to receive(:puts).with(task.to_json)

      task_manager = TaskManager.new
      task_manager.add task
      task_manager.instance_variable_get(:@worker_sockets)[worker_path] = mock_socket
      task_manager.on_task_finished worker_path, nil, nil
    end

    it "can close dead worker" do

      expect(mock_socket).to receive(:close)

      task_manager = TaskManager.new
      task_manager.add task
      task_manager.instance_variable_get(:@worker_sockets)[worker_path] = mock_socket
      task_manager.on_worker_dead worker_path
    end

    it "can send '__KILL__' when there are no tasks left" do

      expect(mock_socket).to receive(:puts).with('__KILL__')

      task_manager = TaskManager.new
      task_manager.instance_variable_get(:@worker_sockets)[worker_path] = mock_socket
      task_manager.on_task_finished worker_path, nil, nil
    end
  end
end