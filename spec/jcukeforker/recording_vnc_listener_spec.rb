require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe RecordingVncListener do
    let(:worker)       { double(Worker, :out => ".", :basename => "foo", :failed? => true) }
    let(:recorder)     { double(ChildProcess, :start => nil, :stop => nil, :io => double('io').as_null_object, :crashed? => false) }
    let(:listener)     { RecordingVncListener.new worker }

    it "starts recording when the task is started" do
      worker_path = 'worker_path'
      feature = 'feature'

      env = ENV['DISPLAY']
      ENV['DISPLAY']= ':1'
      ChildProcess.should_receive(:build).with(
        'ffmpeg',
        '-an',
        '-y',
        '-f', 'x11grab',
        '-r', '5',
        '-s', '1024x768',
        '-i', ':1',
        '-vcodec', 'vp8',
        './feature.webm'
      ).and_return(recorder)

      recorder.should_receive(:start)

      listener.on_task_starting worker, feature
      ENV['DISPLAY'] = env
    end

    it "stops recording when the task is finished" do
      recorder.should_receive(:stop)
      listener.instance_variable_set(:@recorder, recorder)

      listener.on_task_finished worker, nil, nil

      listener.instance_variable_get(:@recorder).should be_nil
    end

    it "stops recording when worker dies" do
      listener.instance_variable_set(:@recorder, recorder)
      recorder.should_receive(:stop)

      listener.on_worker_dead(nil)
    end

    it "deletes the output file if the worker succeeded" do
      recorder.stub(:stop)
      listener.instance_variable_set(:@recorder, recorder)

      worker.should_receive(:failed?).and_return(false)
      listener.should_receive(:output).and_return("./foo.mp4")
      FileUtils.should_receive(:rm_rf).with("./foo.mp4")

      listener.on_task_finished worker, nil, nil
    end

    it "passes along options to recorder" do
      listener = RecordingVncListener.new worker, :codec => "flv"
      env = ENV['DISPLAY']
      ENV['DISPLAY']= ':1'
      ChildProcess.should_receive(:build).with(
        'ffmpeg',
        '-an',
        '-y',
        '-f', 'x11grab',
        '-r', '5',
        '-s', '1024x768',
        '-i', ':1',
        '-vcodec', 'flv',
        './feature.flv'
      ).and_return(recorder)

      listener.on_task_starting worker, 'feature'
      env = ENV['DISPLAY']
    end

  end # RecordingVncListener
end # CukeForker
