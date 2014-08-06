
module JCukeForker
  class ConfigurableVncServer

    def self.create_class(launch_arguments)
      Class.new(VncTools::Server) do

        define_method :launch_arguments do
          launch_arguments
        end
      end
    end
  end
end


