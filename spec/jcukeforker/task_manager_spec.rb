require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe TaskManager do
    let(:worker_path) { '/tmp/jcukeforker-test-socket' }
    let(:feature) { 'feature:1' }
    let(:mock_socket) { double('socket', :puts => nil) }
    let(:mock_file) { double(IO, :puts => nil) }

    it "can register a worker" do

      expect(mock_file).to receive(:write).with("{\"worker\":\"/tmp/jcukeforker-test-socket\",\"feature\":\"feature:1\",\"action\":\"feature\"}#{$-0}")

      task_manager = TaskManager.new [feature], mock_file
      task_manager.on_worker_register worker_path
    end

    it "can finish task" do

      expect(mock_file).to receive(:write).with("{\"worker\":\"/tmp/jcukeforker-test-socket\",\"feature\":\"feature:1\",\"action\":\"feature\"}#{$-0}")

      task_manager = TaskManager.new [feature], mock_file
      task_manager.on_task_finished worker_path, nil, nil
    end

    it "can send '__KILL__' when there are no tasks left" do

      expect(mock_file).to receive(:write).with("{\"action\":\"__KILL__\",\"worker\":\"/tmp/jcukeforker-test-socket\"}#{$-0}")

      task_manager = TaskManager.new [], mock_file
      task_manager.on_task_finished worker_path, nil, nil
    end

    it "can detect failure" do
      task_manager = TaskManager.new [], mock_file
      def task_manager.pop_task(*args); end
      task_manager.on_task_finished worker_path, feature, false
      expect(task_manager.has_failures?).to eql true
    end
  end
end
