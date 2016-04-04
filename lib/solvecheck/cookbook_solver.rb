require 'dep_selector'
require 'yaml'

module Solvecheck
  class CookbookSolver
    attr_accessor :query

    # @param query [Query]
    def initialize(query)
      @query = query
    end

    # @param query [Query]
    def solve
      start_time = Time.now
      reader, writer = IO.pipe

      # Run in a fork because FFI w/ high CPU usage blocks the GVL
      child_pid = fork do
        reader.close
        result = internal_solve(query.to_hash)

        # We serialize to YAML because it preserves symbols
        writer.write result.to_yaml
        writer.close
        exit
      end
      writer.close

      # So that the child fork isn't orphaned when we Ctrl-C
      Signal.trap("INT") do
        kill_child(child_pid)
        exit
      end

      # Set to timeout+1 because we get more info when DepSelector handles it
      watchdog_timeout = (Solvecheck.configuration.timeout_ms + 1000) / 1000
      begin
        Timeout::timeout(watchdog_timeout) do
          Process.wait(child_pid)
        end 
        result = YAML.load(reader.read)
      rescue Timeout::Error
        kill_child(child_pid)
        result = [:error, :watchdog_timeout, []]
      end
      reader.close

      finish_time = Time.now
      SolveResult.new(result, finish_time - start_time)
    end

    private

    def kill_child(pid)
      begin
        Process.kill("KILL", pid)
      rescue Errno::ESRCH
      end
    end

    # This was taken, almost verbatim, from the chef-server:
    #
    # https://github.com/chef/chef-server/blob/7c1df3/src/oc_erchef/apps/chef_objects/priv/depselector_rb/depselector.rb
    def internal_solve(data)
      begin
        # create dependency graph from cookbooks
        graph = DepSelector::DependencyGraph.new

        env_constraint_list = []
        env_constraints = data["environment_constraints"].inject({}) do |acc, env_constraint|
          name, version, constraint = env_constraint
          acc[name] = DepSelector::VersionConstraint.new(constraint_to_str(constraint, version))
          acc
        end

        all_versions = []

        data["all_versions"].each do |vsn|
          name, version_constraints = vsn

          version_constraints.each do |version_constraint| # todo: constraints become an array in ruby
                                                           # due to the erlectricity conversion from
                                                           # tuples
            version, constraints = version_constraint

            # filter versions based on environment constraints
            env_constraint = env_constraints[name]
            if (!env_constraint || env_constraint.include?(DepSelector::Version.new(version)))
              package_version = graph.package(name).add_version(DepSelector::Version.new(version))
              constraints.each do |package_constraint|
                constraint_name, constraint_version, constraint = package_constraint
                version_constraint = DepSelector::VersionConstraint.new(constraint_to_str(constraint, constraint_version))
                dependency = DepSelector::Dependency.new(graph.package(constraint_name), version_constraint)
                package_version.dependencies << dependency
              end
            end
          end

          # regardless of filter, add package reference to all_packages
          all_versions << graph.package(name)
        end

        run_list = data["run_list"].map do |run_list_item|
          item_name, item_constraint_version, item_constraint = run_list_item
          version_constraint = DepSelector::VersionConstraint.new(constraint_to_str(item_constraint, item_constraint_version))
          DepSelector::SolutionConstraint.new(graph.package(item_name), version_constraint)
        end

        timeout_ms = data["timeout_ms"]
        selector = DepSelector::Selector.new(graph, (timeout_ms / 1000.0))

        answer = begin
                   solution = selector.find_solution(run_list, all_versions)
                   packages = []
                   solution.each do |package, v|
                     packages << [package, [v.major, v.minor, v.patch]]
                   end
                   [:ok, packages]
                 rescue DepSelector::Exceptions::InvalidSolutionConstraints => e
                   non_existent_cookbooks = e.non_existent_packages.inject([]) do |list, constraint|
                     list << constraint.package.name
                   end

                   constrained_to_no_versions = e.constrained_to_no_versions.inject([]) do |list, constraint|
                     list << constraint.to_s
                   end

                   error_detail = [[:non_existent_cookbooks, non_existent_cookbooks],
                                   [:constraints_not_met, constrained_to_no_versions]]

                   [:error, :invalid_constraints, error_detail]
                 rescue DepSelector::Exceptions::NoSolutionExists => e
                   most_constrained_cookbooks = e.disabled_most_constrained_packages.inject([]) do |list, package|
                     # WTF: this is the reported error format but I can't find this anywhere in the ruby code
                     list << "#{package.name} = #{package.versions.first.to_s}"
                   end

                   non_existent_cookbooks = e.disabled_non_existent_packages.inject([]) do |list, package|
                     list << package.name
                   end

                   error_detail = [[:message, e.message],
                                   [:unsatisfiable_run_list_item, e.unsatisfiable_solution_constraint.to_s],
                                   [:non_existent_cookbooks, non_existent_cookbooks],
                                   [:most_constrained_cookbooks, most_constrained_cookbooks]]

                   [:error, :no_solution, error_detail]
                 rescue DepSelector::Exceptions::TimeBoundExceeded,
                        DepSelector::Exceptions::TimeBoundExceededNoSolution => e
                   # While dep_selector differentiates between the two solutions, the opscode-chef
                   # API returns the same error regardless of the timeout type. We'll swallow the
                   # difference here and return a unified timeout to erchef
                   [:error, :resolution_timeout]
                 end

        return answer
      end
    end

    def translate_constraint(constraint)
      case constraint
      when Symbol
        case constraint
        when :gt then ">"
        when :gte then ">="
        when :lt then "<"
        when :lte then "<="
        when :eq then "="
        when :pes then "~>"
        else constraint.to_s
        end
      when NilClass
        "="
      else
        constraint
      end
    end

    def constraint_to_str(constraint, constraint_version)
      return nil unless constraint_version
      "#{translate_constraint(constraint)} #{constraint_version}"
    end
  end
end
