module Solvecheck
  class OutdatedRunlistItems < Check
    def run
      return unless solve_result.success?
      unversioned_run_list_pkgs.each_with_object({}) do |name, memo|
        got_vers = packages[name]
        unless artifacts.latest?(name, got_vers)
          msg = { got: got_vers, latest: artifacts.latest(name) }
          warning msg
        end
      end
    end

    def unversioned_run_list_pkgs
      expanded_run_list.reject { |n| n.include?('@') }
    end
  end
end
