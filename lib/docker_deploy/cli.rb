require 'docker_deploy'
require 'thor'
require 'yaml'

module DockerDeploy
  # The command-line interface for DockerDeploy
  class CLI < Thor
    DEFAULT_CONFIG_FILE = 'docker/config.yml'
    SSH_PORT = 22
    HTTP_PORT = 80

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
        option_delimiter = ' '
        command = sprintf('docker run -d --name %s_%s', @options[:application_name], config[:container][:http_port])
        command << option_delimiter + hostname_option
        command << option_delimiter + port_option(config)
        command << option_delimiter + volume_option(environment)
        command << option_delimiter + environment_variables_option(environment)
        command << option_delimiter + @options[:image_name]
        ssh_client.command(command)
      end
    end

    private

    def volume_option(environment)
      volumes = @options[environment.to_sym][:volumes]
      result = ''
      if volumes
        volumes.each { |volume| result << sprintf('-v %s:%s ', volume[:volume][:host], volume[:volume][:guest]) }
      end
      result
    end

    def environment_variables_option(environment)
      env_file = @options[environment.to_sym][:env_file]
      result = ''
      if env_file
        if File.exist?(env_file)
          environment_variables = YAML.load_file(env_file).symbolize_keys
          environment_variables.each do |k, v|
            result << sprintf("-e %s='%s' ", k.upcase, v)
          end
        end
      end
      result.strip
    end

    def port_option(config)
      container_config = config[:container]
      result = ''
      result << sprintf('-p %s:%s:%s ', container_config[:host], container_config[:ssh_port], SSH_PORT)
      result << sprintf('-p %s:%s:%s', container_config[:host], container_config[:http_port], HTTP_PORT)
    end

    def hostname_option
      sprintf('--hostname %s', @options[:application_name])
    end
  end
end
