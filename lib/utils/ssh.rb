module Utils
  # Utility methods for doing things over SSH
  module SSH
    # Intelligently do some things over SSH
    def over_ssh(opts = {})
      result = {}
      fail "MissingSSHHost" unless opts[:host]
      fail "MissingSSHUser" unless opts[:user]
      opts[:timeout] ||= 300 # default to a 5 minute timeout

      remote = Rye::Box.new(
        opts[:host],
        user: opts[:user],
        auth_methods: ['publickey'],
        password_prompt: false
      )

      exception = nil

      output = begin
        Timeout::timeout(opts[:timeout]) do
          yield remote # pass our host back to the user to work with
        end
      rescue Exception => e
        exception = e
      ensure
        remote.disconnect
      end

      result[:exception] = exception
      result[:exit_status] = output.exit_status
      result[:stdout] = output.stdout
      result[:stderr] = output.stderr
      return result
    end
  end
end
