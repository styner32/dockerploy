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
          ssh_client.command('docker ps | grep %s' % @options[:image_prefix])
        end
      end
    end

    desc 'build', 'build an image'
    def build
      command = 'env DOCKER_HOST=%s docker build -t %s .' % [@options[:image_server][:docker_host], @options[:image_name]]
      puts command
      ShellClient.new.command(command)
    end
  end
end
