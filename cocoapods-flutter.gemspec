lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cocoapods-flutter/gem_version"

Gem::Specification.new do |spec|
  spec.name          = "cocoapods-flutter"
  spec.version       = CocoapodsFlutter::VERSION
  spec.authors       = ["firorwang"]
  spec.email         = ["firorwang@sohu-inc.com"]
  spec.description   = "A short description of cocoapods-flutter."
  spec.summary       = "A longer description of cocoapods-flutter."
  spec.homepage      = "https://github.com/EXAMPLE/cocoapods-flutter"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "cocoapods"
  spec.metadata["rubygems_mfa_required"] = "true"
end
