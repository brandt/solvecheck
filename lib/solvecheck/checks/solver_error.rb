module Solvecheck
  class SolverError < Check
    def run
      error solve_result.error if solve_result.error?
    end
  end
end
