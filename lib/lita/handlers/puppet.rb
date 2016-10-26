module Lita
  module Handlers
    class Puppet < Handler
      namespace 'Puppet'
      config :master_hostname, required: true, type: String
      config :ssh_user, required: false, type: String
      config :control_repo_path, required: false, type: String

      route(
        /(puppet|pp)\s+(r10k|deploy)(\s(\S+))?/i,
        :r10k_deploy,
        command: true,
        help: {
          "puppet r10k <env>" => "Deploy the latest puppet code on the puppet master via r10k, optionally specifying an environment."
        }
      )

      def r10k_deploy(response)
        environment = response.matches[0][3]
        control_repo = config.control_repo_path || '/opt/puppet/control'
        user = config.ssh_user || 'lita'
        username = response.user.name

        response.reply("#{username}, I'll get right on that. Give me a moment and I'll let you know how it went.")

        ret = nil

        Timeout::timeout(600) do
          puppet_master = Rye::Box.new(config.master_hostname, user: user)
          puppet_master.cd control_repo

          # Need to use sudo from here on
          puppet_master.enable_sudo

          puppet_master.git :pull

          # scary...
          puppet_master.disable_safe_mode
          command = "r10k deploy environment"
          command << " #{environment}" if environment
          command << ' -pv'
          ret = puppet_master.execute command
          puppet_master.disconnect
        end

        # build a reply
        response.reply("#{username}, your r10k deployment is done!")
        if ret
          response.reply ret.stdout.join("\n")
        else
          response.reply "But didn't seem to work... I think it may have timed out."
        end
      end

      Lita.register_handler(self)
    end
  end
end
