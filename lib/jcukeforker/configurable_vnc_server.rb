
module JCukeForker
  class ConfigurableVncServer < VncTools::Server

    DEFAULT_OPTIONS = {
      :geometry => '1024x768'
      :depth => '24'
      :dpi => '96'
    }

    attr_reader :geometry, :depth, :dpi

    def initialize(opts = {})
      opts = DEFAULT_OPTIONS.dup.merge(opts)

      @geometry = opts[:geometry]
      @depth = opts[:depth]
      @dpi = opts[:dpi]
    end

    def launch_arguments
      %W[-geometry #{geometry} -depth #{depth} -dpi #{dpi}]
    end
  end
end


