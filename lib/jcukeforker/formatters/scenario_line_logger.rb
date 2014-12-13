require 'gherkin/tag_expression'
module JCukeForker
  module Formatters
    class ScenarioLineLogger
      attr_reader :scenarios

      def initialize(tag_expression = Gherkin::TagExpression.new([]))
        @scenarios = []
        @tag_expression = tag_expression
      end

      def visit_feature_element(feature_element)
        if @tag_expression.evaluate(feature_element.source_tags)
          if feature_element.respond_to?(:each_example_row)
            feature_element.each_example_row do |row|
              #TODO remove reflection
              build_scenario(feature_element, row.instance_variable_get(:@cells).first)
            end
          else
            build_scenario(feature_element, feature_element)
          end
        end
      end

      def method_missing(*args)
      end

      private

      def build_scenario(feature_element, sub_element)
        line_number = if sub_element.respond_to?(:line)
                        sub_element.line
                      else
                        sub_element.location.line
                      end
        @scenarios << [feature_element.feature.file, line_number].join(':')
      end
    end
  end
end
