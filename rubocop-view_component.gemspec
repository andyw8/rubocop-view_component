# frozen_string_literal: true

require_relative "lib/rubocop/view_component/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-view_component"
  spec.version = RuboCop::ViewComponent::VERSION
  spec.authors = ["Andy Waite"]
  spec.email = ["andyw8@users.noreply.github.com"]

  spec.summary = "TODO: Write a short summary, because RubyGems requires one."
  spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/andyw8/rubocop-view_component"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/andyw8/rubocop-view_component"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.metadata['default_lint_roller_plugin'] = 'RuboCop::ViewComponent::Plugin'

  spec.add_dependency 'lint_roller', '~> 1.1'
  spec.add_dependency 'rubocop', '>= 1.72.2'
end

