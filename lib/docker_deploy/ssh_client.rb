require 'net/ssh'

module DockerDeploy
  class SSHClient

    attr_accessor :host, :username, :password, :port

    def initialize(host, username, password, port = 22)
      @host = host
      @username = username
      @password = password
      @port = port
    end

    def command(command)
      exit_code = nil
      puts 'From server: %s Running: %s' % [@host, command]
      with_ssh(command) do |command, ssh|
        puts 'Output: '
        ssh.open_channel do |channel|
          channel.exec(command) do |_, success|
            abort "FAILED: couldn't execute command (ssh.channel.exec)" unless success

            channel.on_data do |_,data|
              print data
            end

            channel.on_extended_data do |_,_,data|
              print data
            end

            channel.on_request('exit-status') do |_,data|
              exit_code = data.read_long
            end
          end
          ssh.loop
        end
      end

      result = exit_code == 0
      puts 'Exit Code: %d' % exit_code unless result
      result
    end

    private
    def with_ssh(command, &block)
      Net::SSH.start(@host, @username, password: @password, port: @port) do |ssh|
        block.call(command, ssh)
      end
    end
  end
end