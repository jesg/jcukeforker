module JCukeForker
  class VncListener < AbstractListener

    def initialize(status, opts = {})
      @random = Random.new
      @status = status
    end

    def on_worker_register(worker_path)
      # handle race condition in vnc
      loop do
        begin
          @server = VncTools::Server.new
          @server.start
          ENV['DISPLAY'] = @server.display
          break
        rescue
          sleep @random.rand 5
        end
      end

      @status.update_status :on_display_starting, @server.display
    end

    def on_worker_dead(worker_path)
      @server.stop
      @status.update_status :on_display_stopping, @server.display
    end
  end # VncListener
end # CukeForker
