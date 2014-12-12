module DockerDeploy
  # Wrapper for local shell command
  class ShellClient
    def initialize
    end

    def command(command)
      system(command)
      unless $CHILD_STATUS.success?
        puts sprintf('Exit Code: %d', $CHILD_STATUS.exitstatus)
        return false
      end
      true
    end
  end
end
