module Solvecheck
  class TimeoutWarning < Check
    # Warn if solver was successful but took >80% of timeout_ms
    def run
      return unless solve_result.success?
      duration = solve_result.solve_duration * 1000
      timeout = Solvecheck.configuration.timeout_ms
      pct = duration / timeout.to_f
      if (pct > 0.80)
        warning "Solver approaching timeout: Took: #{duration} ms / Allowed: #{timeout} ms"
      end
    end
  end
end
