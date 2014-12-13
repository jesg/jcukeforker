require File.expand_path("../../../spec_helper", __FILE__)
require 'cucumber/ast/scenario_outline'

module JCukeForker::Formatters
  describe ScenarioLineLogger do
    it "returns scenario names and line numbers for a scenario" do
      logger = ScenarioLineLogger.new

      feature = double("Cucumber::Ast::Feature")
      feature_element = double("Cucumber::Ast::Scenario")

      feature.should_receive(:file).twice.and_return('features/test1.feature')
      feature_element.should_receive(:source_tags).twice.and_return('')
      feature_element.should_receive(:feature).twice.and_return(feature)
      feature_element.should_receive(:line).and_return(3)
      feature_element.should_receive(:line).and_return(6)

      logger.visit_feature_element(feature_element)
      logger.visit_feature_element(feature_element)

      logger.scenarios.length.should == 2
      logger.scenarios[0].should == "features/test1.feature:3"
      logger.scenarios[1].should == "features/test1.feature:6"
    end

    it "returns scenario names and line numbers for a scenario outline" do
      logger = ScenarioLineLogger.new

      feature = double("Cucumber::Ast::Feature")
      row = double("Cucumber::Ast::OutlineTable::ExampleRow")
      cell = double("Cucumber::Ast::Table::Cell", :line => 4)
      feature_element = Cucumber::Ast::ScenarioOutline.new(*Array.new(11) {|a| double(a, :each => true) })
      feature_element.stub(:each_example_row).and_yield(row)

      row.should_receive(:instance_variable_get).with(:@cells).and_return([cell])
      feature.should_receive(:file).and_return('features/test1.feature')
      feature_element.should_receive(:source_tags).and_return('')
      feature_element.should_receive(:feature).and_return(feature)

      logger.visit_feature_element(feature_element)

      logger.scenarios.length.should == 1
      logger.scenarios[0].should == "features/test1.feature:4"
    end
  end
end
