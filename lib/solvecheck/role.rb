require 'chef/run_list/run_list_expansion'

module Solvecheck
  class Role
    attr_accessor :name, :env_run_lists

    def initialize
      @name = ""
      @env_run_lists = { "_default" => [] }
    end

    def cookbooks(env = "_default")
      expanded_run_list(env).map do |item|
        c = Chef::RunList::RunListItem.new(item)
        [c.name.split("::").first, c.version].compact.join("@")
      end
    end

    # run_list == env_run_lists['_default']
    def run_list(env = "_default")
      if env_run_lists.include?(env)
        env_run_lists[env]
      else
        env_run_lists["_default"]
      end
    end

    def run_list=(rl)
      env_run_lists["_default"] = rl
    end

    def expanded_run_list(env = "_default")
      run_list(env).map do |item|
        if item.is_a? Role
          item.expanded_run_list(env)
        else
          item
        end
      end.flatten
    end

    def self.from_hash(hsh)
      role = new
      role.name = hsh[:name]
      role.run_list = hsh[:run_list]
      hsh[:env_run_lists].each do |env, rl|
        role.env_run_lists[env.to_s] = rl
      end
      role
    end
  end
end
