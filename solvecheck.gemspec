# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'solvecheck/version'

Gem::Specification.new do |spec|
  spec.name          = "solvecheck"
  spec.version       = Solvecheck::VERSION
  spec.authors       = ["J. Brandt Buckley"]
  spec.email         = ["brandt@runlevel1.com"]

  spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"

  spec.add_runtime_dependency "ridley", "~> 4.3"
  spec.add_runtime_dependency "chef", "~> 12.6.0"
  spec.add_runtime_dependency "dep_selector", "~> 1.0"
  spec.add_runtime_dependency "version_sorter", "~> 2.0"
  spec.add_runtime_dependency "sequel", "~> 4.7"
  spec.add_runtime_dependency "pg", "~> 0.18"
  spec.add_runtime_dependency "parallel", "~> 1.6"
  spec.add_runtime_dependency "ruby-progressbar"
end
