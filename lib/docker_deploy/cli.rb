require 'docker_deploy'
require 'thor'
require 'yaml'

module DockerDeploy
  # The command-line interface for DockerDeploy
  class CLI < Thor
    DEFAULT_CONFIG_FILE = 'docker/config.yml'
    class_option :config, aliases: ['-c'], type: :string

    def initialize(args = [], opts = {}, config = {})
      super(args, opts, config)
      return unless File.exist?(DEFAULT_CONFIG_FILE)
      config_options = YAML.load_file(DEFAULT_CONFIG_FILE).symbolize_keys
      @options = @options.symbolize_keys.merge(config_options)
    end

    desc 'ps ENVIRONMENT', 'Show running containers'
    def ps(environment)
      server_configs = @options[environment.to_sym][:servers]
      return unless server_configs
      server_configs.each do |config|
        ssh_client = SSHClient.new(config[:host], config[:username], config[:password], config[:port])
        ssh_client.command(sprintf('docker ps | grep %s', @options[:application_name]))
      end
    end

    desc 'build', 'build an image'
    def build
      command = sprintf('env DOCKER_HOST=%s docker build -t %s .', @options[:docker_host], @options[:image_name])
      ShellClient.new.command(command)
    end

    desc 'push', 'push an image'
    def push
      command = sprintf('env DOCKER_HOST=%s docker push %s', @options[:docker_host], @options[:image_name])
      ShellClient.new.command(command)
    end

    desc 'pull', 'pull an image'
    def pull(environment)
      server_configs = @options[environment.to_sym][:servers]
      return unless server_configs
      server_configs.each do |config|
        ssh_client = SSHClient.new(config[:host], config[:username], config[:password], config[:port])
        ssh_client.command(sprintf('docker pull %s', @options[:image_name]))
      end
    end

    desc 'deploy', 'deploy an application'
    def deploy(environment)
      server_configs = @options[environment.to_sym][:servers]
      return unless server_configs
      server_configs.each do |config|
        ssh_client = SSHClient.new(config[:host], config[:username], config[:password], config[:port])
        command = sprintf('docker run -d --name %s_%s --hostname %s %s',
                          @options[:application_name], config[:container][:http_port],
                          @options[:application_name], @options[:image_name])
        ssh_client.command(command)
      end
    end
  end
end
