require 'chef/config'
require 'chef/log'
require 'chef/environment'
require 'chef/cookbook_version'
require 'json'
require 'pp'

require "solvecheck/version"
require "solvecheck/configuration"
require "solvecheck/errors"
require "solvecheck/role"
require "solvecheck/role_list"
require "solvecheck/request"
require "solvecheck/survey"
require "solvecheck/solve_result"
require "solvecheck/artifacts"
require "solvecheck/query"
require "solvecheck/cookbook_solver"
require "solvecheck/environment"
require "solvecheck/environment_collection"
require "solvecheck/problem_finder"

require "solvecheck/check"
require "solvecheck/checks/outdated_runlist_items"
require "solvecheck/checks/solver_error"
require "solvecheck/checks/timeout_warning"

module Solvecheck
  # Query.verbose = true

  def self.solve_by_name(role_name, environment_name = "_default")
    role_list = RoleList.new
    environments = EnvironmentCollection.new
    role = role_list[role_name]
    env = environments[environment_name]
    query = Query.new(role, env)
    query.solve
    query
  end

  def self.solve_all
    survey = Survey.new
    survey.preload
    survey.solve_all
  end

  def self.run
    survey = Survey.new
    survey.preload
    survey.problems
  end
end
