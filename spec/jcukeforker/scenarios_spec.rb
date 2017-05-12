require File.expand_path("../../spec_helper", __FILE__)

module JCukeForker
  describe Scenarios do
    it "returns all scenarios and their line numbers" do
      allow(Scenarios).to receive(:feature_files).and_return(['features/test1.feature', 'features/test2.feature'])
      allow(JCukeForker::NormalisedEncodingFile).to receive(:read).with(/features\/test\d\.feature/).and_return(<<-GHERKIN)
      Feature: Test Feature

        Scenario: Test Scenario 1
          Given I do fake precondition
          When I do fake action
          Then I get fake assertions

        Scenario: Test Scenario 2
          Given I do fake precondition
          When I do fake action
          Then I get fake assertions
      GHERKIN

      all_scenarios = Scenarios.all

      expect(all_scenarios.length).to eql 4
      expect(all_scenarios[0]).to eql  "features/test1.feature:3"
      expect(all_scenarios[1]).to eql "features/test1.feature:8"
      expect(all_scenarios[2]).to eql "features/test2.feature:3"
      expect(all_scenarios[3]).to eql "features/test2.feature:8"
    end

    it "returns all scenarios and their line numbers by tags" do
      allow(Scenarios).to receive(:feature_files).and_return(['features/test1.feature'])
      allow(JCukeForker::NormalisedEncodingFile).to receive(:read).with('features/test1.feature').and_return(<<-GHERKIN)
      Feature: test 1
          @find_me
          Scenario: test scenario 1
            Given nothing happens
          Scenario: test scenario 2
            Given nothing else happens
      GHERKIN

      all_scenarios = Scenarios.by_args(%W[-t @find_me])

      expect(all_scenarios.length).to eql 1
      expect(all_scenarios[0]).to eql "features/test1.feature:3"
    end

    it "returns all scenarios and their line numbers by multiple include tags" do
      allow(Scenarios).to receive(:feature_files).and_return(['features/test1.feature'])
      allow(JCukeForker::NormalisedEncodingFile).to receive(:read).with('features/test1.feature').and_return(<<-GHERKIN)
      Feature: test 1
          @find_me
          Scenario: test scenario 1
            Given nothing happens

          @me_too
          Scenario: test scenario 2
            Given nothing else happens
      GHERKIN

      all_scenarios = Scenarios.by_args(%W[-t @find_me,@me_too])

      expect(all_scenarios.length).to eql 2
      expect(all_scenarios[0]).to eql "features/test1.feature:3"
      expect(all_scenarios[1]).to eql "features/test1.feature:7"
    end

    it "returns all scenarios and their line numbers by multiple and tags" do
      allow(Scenarios).to receive(:feature_files).and_return(['features/test1.feature'])
      allow(JCukeForker::NormalisedEncodingFile).to receive(:read).with('features/test1.feature').and_return(<<-GHERKIN)
      Feature: test 1
          @find_me @me_too
          Scenario: test scenario 1
            Given nothing happens

          @me_too
          Scenario: test scenario 2
            Given nothing else happens
      GHERKIN

      all_scenarios = Scenarios.by_args(%W[-t @find_me -t @me_too])

      expect(all_scenarios.length).to eql 1
      expect(all_scenarios[0]).to eql "features/test1.feature:3"
    end

    it "returns all scenarios and their line numbers by exclusion tag" do
      allow(Scenarios).to receive(:feature_files).and_return(['features/test1.feature'])
      allow(JCukeForker::NormalisedEncodingFile).to receive(:read).with('features/test1.feature').and_return(<<-GHERKIN)
      Feature: test 1
          @find_me
          Scenario: test scenario 1
            Given nothing happens

          @me_too
          Scenario: test scenario 2
            Given nothing else happens
      GHERKIN

      all_scenarios = Scenarios.by_args(%W[-t ~@find_me])

      expect(all_scenarios.length).to eql 1
      expect(all_scenarios[0]).to eql "features/test1.feature:7"
    end
  end
end
