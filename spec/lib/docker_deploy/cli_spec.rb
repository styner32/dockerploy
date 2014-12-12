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
        expect(cli.options).to eq(YAML.load_file(fixture_path).symbolize_keys)
      end
    end

    describe '#ps' do
      it 'runs docker ps in servers' do
        expect_any_instance_of(SSHClient).to receive(:command).with('docker ps | grep app')
        cli = described_class.new
        cli.ps('test')
      end
    end

    describe '#build' do
      it 'runs docker build' do
        expected_command = 'env DOCKER_HOST=tcp://test.host:4243 docker build -t docker/image .'
        expect_any_instance_of(ShellClient).to receive(:command).with(expected_command)
        cli = described_class.new
        cli.build
      end
    end

    describe '#push' do
      it 'pushes the image' do
        expected_command = 'env DOCKER_HOST=tcp://test.host:4243 docker push docker/image'
        expect_any_instance_of(ShellClient).to receive(:command).with(expected_command)
        cli = described_class.new
        cli.push
      end
    end

    describe '#pull' do
      it 'pulls the image' do
        expect_any_instance_of(SSHClient).to receive(:command).with('docker pull docker/image')
        cli = described_class.new
        cli.pull('test')
      end
    end

    describe '#deploy' do
      it 'creates a container on server' do
        expected_command = <<-SHELL
docker run -d --name app_8080 --hostname app -p container.host:1022:22 -p container.host:8080:80   docker/image
SHELL
        expected_command.chomp!
        expect_any_instance_of(SSHClient).to receive(:command).with(expected_command)
        cli = described_class.new
        cli.deploy('test')
      end

      context 'an environment file exists' do
        let(:fixture_path) { 'spec/fixtures/config_with_env_file.yml' }

        it 'creates a container with environment variables' do
          expected_command = <<-SHELL
docker run -d --name app_8080 --hostname app \
-p container.host:1022:22 -p container.host:8080:80  \
-e BRANCH='master' -e APP_ENV='test' docker/image
SHELL
          expected_command.chomp!
          expect_any_instance_of(SSHClient).to receive(:command).with(expected_command)
          cli = described_class.new
          cli.deploy('test')
        end
      end

      context 'volumes exists' do
        let(:fixture_path) { 'spec/fixtures/config_with_volumes.yml' }

        it 'creates a container with volumes' do
          expected_command = <<-SHELL
docker run -d --name app_8080 --hostname app \
-p container.host:1022:22 -p container.host:8080:80 \
-v /opt/app/shared/log:/var/log   \
docker/image
SHELL
          expected_command.chomp!
          expect_any_instance_of(SSHClient).to receive(:command).with(expected_command)
          cli = described_class.new
          cli.deploy('test')
        end
      end
    end
  end
end
