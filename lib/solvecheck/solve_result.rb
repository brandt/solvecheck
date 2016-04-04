module Solvecheck
  class SolveResult
    attr_reader :raw, :solve_duration

    def initialize(raw, solve_duration = nil)
      @solve_duration = solve_duration
      @raw = raw
    end

    def status
      raw[0]
    end

    def error_type
      return unless error?
      raw[1]
    end

    def error_detail
      return unless error?
      (raw[2] || []).to_h
    end

    def error
      return {} unless error?
      { error_type => error_detail }
    end

    def packages
      return {} unless success?
      raw[1].each_with_object({}) do |(name, vers), memo|
        memo[name] = vers.join('.')
      end
    end

    def success?
      status == :ok
    end

    def error?
      status == :error
    end
  end
end
