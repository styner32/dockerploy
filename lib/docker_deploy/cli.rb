require 'docker_deploy'
require 'thor'
require 'yaml'

module DockerDeploy
  class CLI < Thor
    DEFAULT_CONFIG_FILE='docker/config.yml'
    class_option :config, :aliases => ['-c'], :type => :string

    def initialize(args = [], opts = {}, config = {})
      super(args, opts, config)
      if File.exists?(DEFAULT_CONFIG_FILE)
        config_options = YAML.load_file(DEFAULT_CONFIG_FILE).symbolize_keys
        @options = @options.symbolize_keys.merge(config_options)
      end
    end

    desc 'ps ENVIRONMENT', 'Show running containers'
    def ps(environment)
      server_configs = @options[environment.to_sym][:servers]
      if server_configs
        server_configs.each do |config|
          ssh_client = SSHClient.new(config[:host], config[:username], config[:password], config[:port])
          ssh_client.command('docker ps | grep %s' % @options[:application_name])
        end
      end
    end

    desc 'build', 'build an image'
    def build
      command = 'env DOCKER_HOST=%s docker build -t %s .' % [@options[:docker_host], @options[:image_name]]
      ShellClient.new.command(command)
    end

    desc 'push', 'push an image'
    def push
      command = 'env DOCKER_HOST=%s docker push %s' % [@options[:docker_host], @options[:image_name]]
      ShellClient.new.command(command)
    end

    desc 'pull', 'pull an image'
    def pull(environment)
      server_configs = @options[environment.to_sym][:servers]
      if server_configs
        server_configs.each do |config|
          ssh_client = SSHClient.new(config[:host], config[:username], config[:password], config[:port])
          ssh_client.command('docker pull %s' % @options[:image_name])
        end
      end
    end

    desc 'deploy', 'deploy an application'
    def deploy(environment)
      server_configs = @options[environment.to_sym][:servers]
      if server_configs
        server_configs.each do |config|
          ssh_client = SSHClient.new(config[:host], config[:username], config[:password], config[:port])
          ssh_client.command('docker run -d --name %s_%s --hostname %s %s' % [@options[:application_name], config[:container][:http_port], @options[:application_name], @options[:image_name]])
        end
      end
    end
  end
end
