require 'sequel'
require 'zlib'
require 'stringio'
require 'base64'
require 'json'

module Solvecheck
  class RoleList
    include Enumerable

    attr_reader :sql

    def initialize
      @sql = Sequel.connect(Solvecheck.configuration.sql_uri)
    end

    def [](name)
      roles.detect { |m| m.name == name }
    end

    def each(&block)
      roles.each(&block)
    end

    def roles
      @roles ||= fetch_roles
    end

    private

    def fetch_roles
      # Pass 1: Build initial role list
      role_list = {}
      sql.from(:roles).map do |role|
        begin
          so = Zlib::GzipReader.new(StringIO.new(role[:serialized_object])).read
          res = JSON.parse(so, create_addtions: false, symbolize_names: true)
          r = Role.from_hash(res)
          role_list[r.name] = r
        rescue => e
          # If the JSON doesn't parse just move on
          warn "Error parsing role: #{e}"
          next
        end
      end

      # Pass 2: Substitute 'role' items in each run_list with pointers to role object
      substitute_runlist_roles(role_list)

      role_list.values
    end

    # Substitutes occurrences of role[name] in all the run_lists with a
    # reference to the role object.
    def substitute_runlist_roles(role_list)
      role_list.each do |_, role|
        role.env_run_lists.each do |env, run_list|
          role.env_run_lists[env] = run_list.map do |item|
            if /^role\[(?<name>[^\]]+)\]$/ =~ item
              if role_list.include?(name)
                role_list[name]
              else
                warn "Role '#{role.name}' has a role in its run_list that we do not know about: #{name}"
                # Item will be omitted
              end
            else
              item
            end
          end.compact
        end
      end
    end

  end
end
