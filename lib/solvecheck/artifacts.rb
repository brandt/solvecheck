require 'json'
require 'version_sorter'
require 'open-uri'

module Solvecheck
  class Artifacts
    include Enumerable

    attr_reader :timestamp
    attr_writer :universe

    def initialize
    end

    def each(&block)
      universe.each(&block)
    end

    # @param name [String] cookbook name
    def [](name)
      universe[name]
    end

    # @param name [String] cookbook name
    def latest(name)
      return unless universe.include?(name)
      VersionSorter.sort(universe[name].keys).last
    end

    # @param name [String] cookbook name
    # @param vers [String] exact version
    def latest?(name, vers)
      latest(name) == vers
    end

    def preload
      universe
      self
    end

    def universe
      @universe ||= download
    end

    # @param hsh [Hash] artifacts in the format returned by Berkshelf
    def self.from_hash(hsh)
      a = new
      a.universe = hsh
      a
    end

    # @param path [String] path to JSON file in the format used by Berkshelf
    def self.from_file(path)
      a = new
      raw = File.read(File.expand_path(path))
      a.universe = JSON.parse(raw)
      a
    end

    def download
      warn "Getting artifact universe (src: #{Solvecheck.configuration.berkshelf_url})..."
      @universe = JSON.parse(open(Solvecheck.configuration.berkshelf_url).read)
      @timestamp = Time.now
      @universe
    end
  end
end
