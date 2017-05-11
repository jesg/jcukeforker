require 'cucumber/core'
require 'cucumber/core/filter'

module JCukeForker

  #
  # CukeForker::Scenarios.by_args(args)
  #
  # where 'args' is a String of cucumber options
  #
  # For example:
  # CukeForker::Scenarios.by_args(%W[-p my_profile -t @edition])
  # will return an array of scenarios and their line numbers that match
  # the tags specified in the cucumber profile 'my_profile' AND have the '@edition' tag
  #

  class Scenarios
    include Cucumber::Core
    def self.by_args(args)
      options = Cucumber::Cli::Options.new(STDOUT, STDERR, :default_profile => 'default')
      tagged(options.parse!(args)[:tag_expressions])
    end

    def self.all
      any_tag = []
      tagged any_tag
    end

    def self.tagged(tags)
      scenario_list = ScenarioList.new
      feature_files.each do |feature|
        source = JCukeForker::NormalisedEncodingFile.read(feature)
        file = Cucumber::Core::Gherkin::Document.new(feature, source)
        self.new.execute([file], [Cucumber::Core::Test::TagFilter.new(tags)], scenario_list)
      end
      scenario_list.scenarios
    end

    def self.feature_files
      Dir.glob('**/**.feature')
    end
  end
end
