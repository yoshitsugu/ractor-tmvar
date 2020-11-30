# frozen_string_literal: true

require_relative "lib/ractor/tmvar/version"

Gem::Specification.new do |spec|
  spec.name          = "ractor-tmvar"
  spec.version       = Ractor::TMVar::VERSION
  spec.authors       = ["yoshitsugu"]
  spec.email         = ["yoshitsugu@users.noreply.github.com"]

  spec.summary       = "Ractor::TMVar"
  spec.description   = "Introduce Ractor::TMVar based on Ractor::TVar"
  spec.homepage      = "https://github.com/yoshitsugu/ractor-tmvar"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.2")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ractor-tvar", "~> 0.3.0"
end
