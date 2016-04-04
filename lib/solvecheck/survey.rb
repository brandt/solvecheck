require 'parallel'
require 'json'

module Solvecheck
  class Survey
    attr_accessor :role_list, :artifacts, :environments

    def initialize
      @role_list = RoleList.new
      @artifacts = Artifacts.new
      @environments = EnvironmentCollection.new
    end

    # Download environments and artifacts beforehand to avoid duplicate work
    def preload
      environments.preload
      artifacts.preload
      self
    end

    def solve_all
      # Parallel.map(tasklist, in_processes: process_count, progress: "Solving all") do |q|
      Parallel.map(tasklist, in_threads: process_count) do |q|
      # tasklist.map do |q|
        res = q.solve
        warn "Finished solving #{q.role.name} in #{q.environment.name} at #{Time.now}"
        q
      end
    end

    def problems
      solve_all.map do |q|
        pf = ProblemFinder.new(q)
        pf.analyze

        if pf.problem?
          warn "Found problems with #{q.role.name} in #{q.environment.name}"
          pp pf.analysis
        end

        # if result.success?
        #   puts "Finished solving in #{result.solve_duration} sec"
        #   pp result.packages
        # end

        warn ""
      end
    end

    def tasklist
      role_list.map do |role|
        environments.map { |env| Query.new(role, env, artifacts) }
      end.flatten
    end

    def process_count
      Solvecheck.configuration.parallelism
    end
  end
end
