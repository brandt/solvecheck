module Solvecheck
  class EnvironmentCollection
    include Request
    include Enumerable

    attr_accessor :members

    def initialize
      warn "Initializing environment collection..."
    end

    def preload
      members.each { |e| e.preload }
      self
    end

    def each(&block)
      members.each(&block)
    end

    # @param name [String] environment name
    # @return [Environment, nil]
    def [](name)
      members.detect { |m| m.name == name }
    end

    # @return [Array<Environment>] list of environments
    def members
      @members ||= environment_names.map { |e| Environment.new(e) }
    end

    private

    # @return [Array<String>] list of environment names; filters those not whitelisted
    def environment_names
      request.get('/environments').keys.select { |e| whitelisted? e }
    end

    # @param env [String] environment name
    # @return [Boolean] whether environment has been whitelisted
    # @note Always returns true if whitelist is empty
    def whitelisted?(env)
      whitelist = Solvecheck.configuration.environment_whitelist
      return true if whitelist.empty?
      whitelist.include? env
    end
  end
end
