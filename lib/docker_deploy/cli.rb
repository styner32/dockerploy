require 'docker_deploy'
require 'thor'
require 'sshkit'

module DockerDeploy
  class CLI < Thor
    def initialize(args = [], opts = {}, config = {})
      super(args, opts, config)
    end

    desc 'ps ENVIRONMENT', 'Show running containers'
    def ps(environment)
    end
  end
end
