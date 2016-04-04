module Solvecheck
  class Check
    attr_accessor :warnings, :errors, :query

    def initialize(query)
      @query = query
      @warnings = []
      @errors = []
    end

    def run
      raise NotImplementedError
    end

    def error(msg)
      errors << msg
    end

    def warning(msg)
      warnings << msg
    end

    def critical?
      status == :error
    end

    def ok?
      status == :ok
    end

    def role
      query.role
    end

    def expanded_run_list
      query.run_list
    end

    def environment
      query.environment
    end

    def artifacts
      query.artifacts
    end

    def solve_result
      query.result
    end

    def packages
      solve_result.packages
    end

    def status
      return :error unless errors.empty?
      return :warning unless warnings.empty?
      :ok
    end

    def results
      { check: self.class.to_s, status: status, warnings: warnings, errors: errors }
    end
  end
end
