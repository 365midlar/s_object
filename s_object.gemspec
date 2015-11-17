# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 's_object/version'

Gem::Specification.new do |spec|
  spec.name          = "s_object"
  spec.version       = SObject::VERSION
  spec.authors       = ["Bjarki Gudlaugsson"]
  spec.email         = ["bjarki@365.is"]

  spec.summary       = %q{An ActiveRecord-like ORM for Salesforce s_objects for Rails}
  spec.description   = %q{Allows for querying and storing of s_objects using a familiar API}
  spec.homepage      = "http://www.github.com/365midlar/s_object"
  spec.license       = "MIT"

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
  spec.add_development_dependency "restforce", "~> 2.1"
  spec.add_development_dependency "minitest", "~> 5.8"
  spec.add_development_dependency "minitest-reporters", "~> 1.0"
  spec.add_development_dependency "mocha", "~> 1.1"
  spec.add_development_dependency "byebug", "~> 6.0"
end
