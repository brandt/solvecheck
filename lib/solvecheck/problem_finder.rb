module Solvecheck
  class ProblemFinder
    attr_reader :query, :analysis
    attr_accessor :solve_result

    CHECKS = [
      "OutdatedRunlistItems",
      "SolverError",
      "TimeoutWarning"
    ]

    def initialize(query)
      @query = query
      @analysis = []
    end

    def analyze
      @analysis = CHECKS.each_with_object([]) do |c, memo|
        check = Kernel.const_get("Solvecheck::#{c}").new(query)
        check.run
        memo << check
      end
    end

    # any check has status :warning or :error
    def problem?
      analysis.any? { |c| !c.ok? }
    end

    # no checks have status :error
    def success?
      !analysis.any? { |c| c.critical? }
    end
  end
end
