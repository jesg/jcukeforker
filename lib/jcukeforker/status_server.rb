require 'socket'

module JCukeForker
  class StatusServer
    include Observable

    attr_reader :port

    def initialize(port = '6333')
      @server = ::TCPServer.new 'localhost', port
      @port = @server.connect_address.ip_port
    end

    def run
      loop { handle_connection @server.accept }
    end

    def shutdown
      @server.close if @server
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
