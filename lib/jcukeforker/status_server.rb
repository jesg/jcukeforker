require 'socket'

module JCukeForker
  class StatusServer
    include Observable

    attr_reader :port

    def initialize(port = '6333')
      @server = ::TCPServer.new 'localhost', port
      @port = @server.connect_address.ip_port
      @thread_pool = []
    end

    def run
      @master_thread = Thread.new do
        loop do
          socket = @server.accept
          @thread_pool << Thread.new { handle_connection(socket) }
        end
      end
    end

    def shutdown
      if @server
        @server.close
        @master_thread.terminate
        @thread_pool.each(&:terminate)
      end
    end

    def handle_connection(socket)
      until socket.eof? do
        raw_message = socket.gets
        json_obj = JSON.parse raw_message
        fire json_obj.first, *json_obj[1..-1]
      end
      socket.close
    end

    private

    def fire(*args)
      changed
      notify_observers *args
    end
  end
end
