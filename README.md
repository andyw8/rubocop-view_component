# rubocop-view_component

A RuboCop extension that encourages [ViewComponent best practices](https://viewcomponent.org/best_practices.html).

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
- **ViewComponent/PreferComposition** - Avoid inheriting one ViewComponent from another (prefer composition)
- **ViewComponent/TestRenderedOutput** - Encourage testing rendered output over private methods

## Optional Configuration

### Base Class

By default, the cops detect classes that inherit from `ViewComponent::Base` or `ApplicationComponent`. If your project uses a different base class (e.g. `Primer::Component`), you can configure additional parent classes under `AllCops`, for example:

```yaml
# .rubocop.yml
AllCops:
  ViewComponentParentClasses:
    - MyApp::BaseComponent
```

### No Super

View Component convention is to not calling `super` in component initializers, but that may cause `Lint/MissingSuper` failures from RuboCop. We suggest disabling that rule for your view components directory, for example:

```yaml
# .rubocop.yml
Lint/MissingSuper:
  Exclude:
    - 'app/components/**/*'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Real-World Verification

The cops are tested against real-world component libraries as baselines to catch regressions.

The [`script/verify`](script/verify) script downloads component libraries (cached in `verification/`), runs all ViewComponent cops against them, and compares the results to checked-in snapshots. This runs automatically in CI.

### Primer ViewComponents

To verify against [primer/view_components](https://github.com/primer/view_components) locally:

```bash
script/verify primer
```

If you intentionally change cop behavior, regenerate the snapshot:

```bash
script/verify primer --regenerate
```

To force download the latest Primer source:

```bash
script/verify primer --update
```

### x-govuk Components

To verify against [x-govuk/govuk-components](https://github.com/x-govuk/govuk-components) locally:

```bash
script/verify govuk
```

If you intentionally change cop behavior, regenerate the snapshot:

```bash
script/verify govuk --regenerate
```

To force download the latest x-govuk source:

```bash
script/verify govuk --update
```

### Polaris ViewComponents

To verify against [baoagency/polaris_view_components](https://github.com/baoagency/polaris_view_components) locally:

```bash
script/verify polaris
```

If you intentionally change cop behavior, regenerate the snapshot:

```bash
script/verify polaris --regenerate
```

To force download the latest Polaris source:

```bash
script/verify polaris --update
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andyw8/rubocop-view_component.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
