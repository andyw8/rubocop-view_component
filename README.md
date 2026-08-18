# rubocop-view_component

A RuboCop extension that encourages [ViewComponent best practices](https://viewcomponent.org/best_practices.html).

## Installation

This gem requires [rubydex](https://github.com/Shopify/rubydex) for project-wide class ancestry resolution. Add to your Gemfile:

```ruby
gem 'rubocop-view_component', require: false
```

Add to your `.rubocop.yml`:

```yaml
require:
  - rubocop-view_component

AllCops:
  UseProjectIndex: true
  ProjectIndexIncludesGems: true
```

`ProjectIndexIncludesGems` is required so the cops can resolve ancestry chains that pass through gem classes (e.g. `ViewComponent::Base`). Without it, the cops cannot detect ViewComponent inheritance and fall back to conservative behavior.

For more background on how RuboCop uses rubydex for cross-file analysis, see [RuboCop 1.89: Project-Wide Analysis with Rubydex](https://metaredux.com/posts/2026/08/05/rubocop-1-89.html).

## Cops

This gem provides several cops to enforce ViewComponent best practices:

- **ViewComponent/ComponentSuffix** - Enforce `-Component` suffix for ViewComponent classes
- **ViewComponent/NoGlobalState** - Prevent direct access to `params`, `request`, `session`, etc.
- **ViewComponent/PreferPrivateMethods** - Suggest making helper methods private (analyzes ERB templates to avoid flagging methods used in views)
- **ViewComponent/PreferSlots** - Detect HTML parameters that should be slots
- **ViewComponent/PreferComposition** - Avoid inheriting one ViewComponent from another (prefer composition)
- **ViewComponent/TestRenderedOutput** - Encourage testing rendered output over private methods
- **ViewComponent/MissingPreview** - Ensure every ViewComponent has a corresponding preview file (requires `PreviewPaths` configuration). Abstract base classes with descendants are automatically exempt.

## Optional Configuration

### Components Directory

Several cops (`ComponentSuffix`, `PreferComposition`, `MissingPreview`, `TestRenderedOutput`) default to running only on files under `app/components/`. If your project uses a different path, override `Include` in your `.rubocop.yml`:

```yaml
# .rubocop.yml
ViewComponent/ComponentSuffix:
  Include:
    - 'app/components/**/*.rb'
    - 'engines/*/app/components/**/*.rb'
```

### No Super

ViewComponent convention is to not call `super` in component initializers, but that may cause `Lint/MissingSuper` failures from RuboCop. We suggest disabling that rule for your view components directory, for example:

```yaml
# .rubocop.yml
Lint/MissingSuper:
  Exclude:
    - 'app/components/**/*'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version:

1. Update the version number in `lib/rubocop/view_component/version.rb`
2. Run `bundle install` to update `Gemfile.lock`
3. Commit and push both files
4. Trigger the [Push Gem](https://github.com/andyw8/rubocop-view_component/actions/workflows/push_gem.yml) workflow via GitHub Actions (uses trusted publishing — no API key needed)

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
