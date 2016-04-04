require 'chef/rest'

module Solvecheck
  module Request
    def request
      Request.request
    end

    def self.config
      Solvecheck.configuration
    end

    def self.request
      @request ||= Chef::REST.new(config.chef_server_url, config.node_name, File.expand_path(config.client_key))
    end
  end
end
