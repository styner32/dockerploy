module DockerDeploy
  class ShellClient
    def initialize
    end

    def command(command)
      system(command)
      unless $?.success?
        puts 'Exit Code: %d' % $?.exitstatus
        return false
      end
      true
    end
  end
end