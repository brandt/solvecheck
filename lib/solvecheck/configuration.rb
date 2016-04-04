module Solvecheck
  class Configuration
    attr_accessor :chef_server_url
    attr_accessor :node_name
    attr_accessor :client_key
    attr_accessor :berkshelf_url
    attr_accessor :timeout_ms
    attr_accessor :sql_username
    attr_accessor :sql_password
    attr_accessor :sql_host
    attr_accessor :sql_port
    attr_accessor :sql_dbname
    attr_accessor :parallelism
    attr_accessor :environment_whitelist

    # Defaults
    def initialize
      @chef_server_url = 'https://localhost'
      @berkshelf_url   = 'http://localhost:26200/universe'
      @timeout_ms      = 5000  # ms
      @sql_host        = '127.0.0.1'
      @sql_port        = 5432
      @sql_username    = 'opscode_chef'
      @sql_dbname      = 'opscode_chef'
      @parallelism     = 20
      @environment_whitelist = []
    end

    def sql_uri
      "postgres://#{sql_username}:#{sql_password}@#{sql_host}:#{sql_port}/#{sql_dbname}"
    end
  end

  # @return [Solvecheck::Configuration] Solvecheck's current configuration
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Set Solvecheck's configuration
  # @param config [Solvecheck::Configuration]
  def self.configuration=(config)
    @configuration = config
  end

  # Modify Solvecheck's current configuration
  # @yieldparam [Solvecheck::Configuration] config current Clearance config
  # ```
  # Solvecheck.configure do |config|
  #   config.chef_server_url = 'https://chef.ops.sendgrid.net'
  # end
  # ```
  def self.configure
    yield configuration
  end
end
