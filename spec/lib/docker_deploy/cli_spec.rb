require 'spec_helper'

module DockerDeploy
  describe CLI do
    let(:fixture_path) { 'spec/fixtures/config.yml' }
    before do
      stub_const('DockerDeploy::CLI::DEFAULT_CONFIG_FILE', fixture_path)
    end

    describe 'initialize' do
      it 'initializes with config file' do
        cli = described_class.new
        expect(cli.options).to eq(YAML::load_file(fixture_path).symbolize_keys)
      end
    end

    describe '#ps' do
      it 'runs docker ps in servers' do
        allow_any_instance_of(SSHClient).to receive(:command).with('docker ps | grep prefix')
        cli = described_class.new
        cli.ps(:staging)
      end
    end
  end
end
