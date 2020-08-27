# frozen_string_literal: true

require File.expand_path('../spec_helper', __dir__)

RSpec.describe Rcov::CircleCi do
  before do
    allow(ENV).to receive(:[]).with('CIRCLE_PROJECT_USERNAME').and_return('EdgePetrol')
    allow(ENV).to receive(:[]).with('CIRCLE_PROJECT_REPONAME').and_return('danger-rcov')
  end

  describe '#get_report_urls_by_branch' do
    let(:response) { File.read(File.dirname(__FILE__) + '/../support/fixtures/tree_ci.json') }
    let(:curr_cov_response) { File.read(File.dirname(__FILE__) + '/../support/fixtures/current_circle_ci.json') }
    let(:master_cov_response) { File.read(File.dirname(__FILE__) + '/../support/fixtures/master_circle_ci.json') }

    before do
      allow(ENV).to receive(:[]).with('CIRCLE_TOKEN').and_return('token')
      allow(ENV).to receive(:[]).with('CIRCLE_BUILD_NUM').and_return(56)

      allow(Net::HTTP).to receive_message_chain(:get_response, :code).and_return('200')
      allow(URI).to receive_message_chain(:parse, :read).and_return(response)

      current_coverage = Struct.new(:read)
      allow(URI).to receive(:parse).with('https://circleci.com/api/v1.1/project/github/EdgePetrol/danger-rcov/56/artifacts?circle-token=token').and_return(current_coverage)
      allow(current_coverage).to receive(:read).and_return(curr_cov_response)

      coverage = Struct.new(:read)
      allow(URI).to receive(:parse).with('https://circleci.com/api/v1.1/project/github/EdgePetrol/danger-rcov/85/artifacts?circle-token=token').and_return(coverage)
      allow(coverage).to receive(:read).and_return(master_cov_response)
    end

    it 'returns the correct urls' do
      expect(described_class.get_report_urls_by_branch('staging')).to eq(
        [
          'https://current.circle-artifacts.com/0/coverage/coverage.json?circle-token=token&branch=',
          'https://master.circle-artifacts.com/0/coverage/coverage.json?circle-token=token&branch=staging'
        ]
      )
    end
  end
end
