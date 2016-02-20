
module JCukeForker
  class StatusServer
    include Observable

    attr_reader :io_in

    def initialize(io_in)
      @io_in = File.open(io_in, 'r')
      @io_in.sync = true
    end

    def run
      @master_thread = Thread.new do
        loop do
          raw_message = @io_in.gets(sep=$-0)
          next if raw_message.nil?
          handle_message(raw_message)
        end
      end
    end

    def shutdown
      if @io_in
        @io_in.close
        @master_thread.terminate
      end
    end

    def handle_message(raw_message)
      json_obj = JSON.parse raw_message
      fire json_obj.first, *json_obj[1..-1]
    end

    private

    def fire(*args)
      changed
      notify_observers *args
    end
  end
end
