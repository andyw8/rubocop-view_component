# RuboCop::ViewComponent

> **Note:** This gem was vibe-coded and is not yet ready for real-world use. It's currently experimental and may have bugs or incomplete features. Contributions are welcome!

A RuboCop extension that enforces [ViewComponent best practices](https://viewcomponent.org/best_practices.html).

## Installation

Add to your Gemfile:

```ruby
gem 'rubocop-view_component', require: false
```

Add to your `.rubocop.yml`:

```yaml
require:
  - rubocop-view_component
```

## Cops

This gem provides several cops to enforce ViewComponent best practices:

- **ViewComponent/ComponentSuffix** - Enforce `-Component` suffix for ViewComponent classes
- **ViewComponent/NoGlobalState** - Prevent direct access to `params`, `request`, `session`, etc.
- **ViewComponent/PreferPrivateMethods** - Suggest making helper methods private (analyzes ERB templates to avoid flagging methods used in views)
- **ViewComponent/PreferSlots** - Detect HTML parameters that should be slots
- **ViewComponent/PreferComposition** - Discourage deep inheritance chains
- **ViewComponent/TestRenderedOutput** - Encourage testing rendered output over private methods

See [PLAN.md](PLAN.md) for detailed cop descriptions and implementation status.

## Usage

Run RuboCop as usual:

```bash
bundle exec rubocop
```

## Configuration

By default, all cops detect classes that inherit from `ViewComponent::Base` or `ApplicationComponent`. If your project uses a different base class (e.g. `Primer::Component`), you can configure additional parent classes under `AllCops`:

```yaml
# .rubocop.yml
AllCops:
  ViewComponentParentClasses:
    - Primer::Component
    - MyApp::BaseComponent
```

This applies to all ViewComponent cops.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Primer Verification

The cops are tested against [primer/view_components](https://github.com/primer/view_components) as a real-world baseline, and to catch regressions. The script [`verify_against_primer.rb`](script/verify_against_primer.rb) copies the Primer repo, runs all ViewComponent cops against it, and compares the results to a checked-in snapshot ([`expected_primer_failures.json`](spec/expected_primer_failures.json)). This runs automatically in CI.

To verify locally:

```bash
bundle exec ruby script/verify_against_primer.rb
```

If you intentionally change cop behavior, regenerate the snapshot:

```bash
bundle exec ruby script/verify_against_primer.rb --regenerate
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andyw8/rubocop-view_component.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
