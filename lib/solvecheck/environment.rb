module Solvecheck
  class Environment
    include Request

    attr_accessor :name, :constraints

    # @param name [String] environment name
    def initialize(name)
      @name = name
    end

    def preload
      constraints
      self
    end

    # @return [Hash<String, Hash>] environment_name => constraints
    def constraints
      @constraints ||= request.get("/environments/#{name}").cookbook_versions
    end

    def to_s
      name
    end

    # @param hsh [Hash] environment in the following format:
    #   { "name" => "foo", "constraints" => { "bar" => "~> 1.0" } }
    # @return [Environment]
    def self.from_hash(hsh)
      e = new(hsh['name'])
      e.constraints = hsh['constraints']
      e
    end
  end
end
