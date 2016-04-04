module Solvecheck
  # Adapts Sample for use with CookbookSolver
  class Query
    attr_accessor :role, :environment, :artifacts
    attr_reader :result

    # @param role [Role]
    # @param environment [Environment]
    # @param artifacts [Artifacts]
    def initialize(role, environment, artifacts = Artifacts.new)
      @role = role
      @environment = environment
      @artifacts = artifacts
      validate
    end

    def validate
      raise NoRoleError if role.nil?
      raise NoEnvironmentError if environment.nil?
      raise NoArtifactsError if artifacts.nil?
    end

    # @return [Hash] format used by the upstream solver
    def to_hash
      {
        "environment_constraints" => environment_constraints,
        "run_list"                => run_list,
        "all_versions"            => all_versions,
        "timeout_ms"              => timeout_ms
      }
    end

    def solve
      if verbose
        warn "Solving #{role.name} at #{Time.now}:"
        warn "- Chef Environment: #{environment.name}"
        warn "- Run List: #{role.run_list.inspect}"
        warn "- Expanded Run List: #{role.expanded_run_list.inspect}"
        warn "- Run List Cookbooks: #{role.cookbooks.inspect}"
        warn "- Env Constraints: #{environment.constraints.inspect}"
      end
      @result ||= self.to_solver.solve
    end

    def to_solver
      CookbookSolver.new(self)
    end

    def run_list
      role.cookbooks(environment.name)
    end

    def inspect
      "#<Solvecheck::Query:#{"0x00%x" % (object_id << 1)}>"
    end

    def verbose
      Query.verbose
    end

    def self.verbose
      @verbose || false
    end

    # @param verbose [Boolean]
    def self.verbose=(verbose)
      @verbose = verbose
    end

    private

    # Converts a name and constraint to the format the solver expects it in
    #
    # Example:
    #
    # - "foo", "~> 1.4" becomes ["foo", "1.4", "~>"]
    #
    # @note We transform this here because in order to avoid modifications to
    #   the solver thus allowing us to track upstream changes more easily.
    def constraint_to_a(name, constraint)
      op, vers = constraint.split(" ")
      [name, vers, op]
    end

    def environment_constraints
      environment.constraints.map { |n, c| constraint_to_a(n, c) }
    end

    def all_versions
      artifacts.map do |name, versions|
        version_list = versions.map do |version, info|
          deps = info["dependencies"].map { |name, constraint| constraint_to_a(name, constraint) }
          [version, deps]
        end
        [name, version_list]
      end
    end

    def timeout_ms
      Solvecheck.configuration.timeout_ms
    end
  end
end
