require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerRcov do
    it "should be a plugin" do
      expect(Danger::DangerRcov.new(nil)).to be_a Danger::Plugin
    end

    describe "with Dangerfile" do
      let(:current_url) { double('URI::HTTP') }
      let(:master_url) { double('URI::HTTP') }

      before do
        ENV['CIRCLE_PULL_REQUEST'] = 'danger-rcov/123'
        ENV['CIRCLE_TOKEN'] = 'circle-token'

        @dangerfile = testing_dangerfile
        @rcov_plugin = @dangerfile.rcov

        @current_circle_ci = File.read(File.dirname(__FILE__) + '/support/fixtures/current_circle_ci.json')
        @master_circle_ci = File.read(File.dirname(__FILE__) + '/support/fixtures/master_circle_ci.json')

        @current_coverage = File.read(File.dirname(__FILE__) + '/support/fixtures/current_coverage.json')
        @master_coverage = File.read(File.dirname(__FILE__) + '/support/fixtures/master_coverage.json')
      end

      it "code coverage different" do
        allow(URI).to receive(:parse).with('https://current.dev').and_return(current_url)
        allow(current_url).to receive(:read).and_return(@current_circle_ci)
        allow(URI).to receive(:parse).with('https://current.circle-artifacts.com/0/coverage/coverage.json?circle-token=circle-token').and_return(current_url)
        allow(Net::HTTP).to receive(:get_response).with(current_url).and_return(Struct.new(:body).new(@current_coverage))

        allow(URI).to receive(:parse).with('https://master.dev').and_return(master_url)
        allow(master_url).to receive(:read).and_return(@master_circle_ci)
        allow(URI).to receive(:parse).with('https://master.circle-artifacts.com/0/coverage/coverage.json?circle-token=circle-token').and_return(master_url)
        allow(Net::HTTP).to receive(:get_response).with(master_url).and_return(Struct.new(:body).new(@master_coverage))

        expect(@rcov_plugin.report(current_url: 'https://current.dev', master_url: 'https://master.dev')).to eq("```diff\n@@           Coverage Diff            @@\n##           master     #123     +/-  ##\n========================================\n+ Coverage   81.62%   79.16%  -2.46%\n========================================\n  Files          85       85\n+ Lines        1708     1699      -9\n========================================\n+ Misses        314      354     +40\n```")
      end

      it "same code coverage" do
        allow(URI).to receive(:parse).with('https://current.dev').and_return(current_url)
        allow(current_url).to receive(:read).and_return(@current_circle_ci)
        allow(URI).to receive(:parse).with('https://current.circle-artifacts.com/0/coverage/coverage.json?circle-token=circle-token').and_return(current_url)
        allow(Net::HTTP).to receive(:get_response).with(current_url).and_return(Struct.new(:body).new(@current_coverage))

        allow(URI).to receive(:parse).with('https://master.dev').and_return(master_url)
        allow(master_url).to receive(:read).and_return(@master_circle_ci)
        allow(URI).to receive(:parse).with('https://master.circle-artifacts.com/0/coverage/coverage.json?circle-token=circle-token').and_return(master_url)
        allow(Net::HTTP).to receive(:get_response).with(master_url).and_return(Struct.new(:body).new(@current_coverage))

        expect(@rcov_plugin.report(current_url: 'https://current.dev', master_url: 'https://master.dev')).to eq("```diff\n@@           Coverage Diff            @@\n##           master     #123     +/-  ##\n========================================\n  Coverage   79.16%   79.16%\n========================================\n  Files          85       85\n  Lines        1699     1699\n========================================\n  Misses        354      354\n```")
      end
    end
  end
end
