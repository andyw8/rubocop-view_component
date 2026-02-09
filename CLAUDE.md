# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a RuboCop extension that enforces ViewComponent best practices. It provides custom cops that detect anti-patterns and style issues specific to ViewComponent development.

## Common Commands

### Testing
- `rake spec` - Run all RSpec tests
- `bundle exec rspec spec/rubocop/cop/view_component/FILENAME_spec.rb` - Run a specific spec file
- `rake standard` - Run Standard (RuboCop) linting
- `rake` - Run both tests and linting (default task)

### Verification
The project includes a verification system that tests cops against real-world component libraries:

- `script/verify primer` - Verify against Primer ViewComponents
- `script/verify govuk` - Verify against x-govuk components
- `script/verify polaris` - Verify against Polaris ViewComponents
- `script/verify LIBRARY --regenerate` - Update expected results after intentional changes
- `script/verify LIBRARY --update` - Force re-download latest library source

### Development
- `bundle exec rake new_cop[ViewComponent/CopName]` - Generate a new cop with template files

## Code Architecture

### Cop Structure

All cops inherit from `RuboCop::Cop::Base` and are located in `lib/rubocop/cop/view_component/`. Each cop:

1. Includes `ViewComponent::Base` module for shared helper methods
2. Defines detection logic in `on_class`, `on_def`, or other AST node callbacks
3. Has configuration in `config/default.yml`
4. Has corresponding specs in `spec/rubocop/cop/view_component/`

### Shared Modules

**`ViewComponent::Base`** (`lib/rubocop/cop/view_component/base.rb`)
- Provides `view_component_class?(node)` - Detects ViewComponent classes
- Provides `view_component_parent?(node)` - Checks if inheriting from ViewComponent::Base, ApplicationComponent, or configured parent classes
- Provides `inside_view_component?(node)` - Checks if code is within a ViewComponent

**`TemplateAnalyzer`** (`lib/rubocop/cop/view_component/template_analyzer.rb`)
- Used by PreferPrivateMethods cop to analyze ERB templates
- Extracts method calls from templates to avoid flagging template-used methods as private candidates
- Handles both sibling templates (`component.html.erb`) and sidecar templates (`component/component.html.erb`)
- Uses the `herb` gem to parse ERB and extract Ruby code

### Configuration

The `AllCops` config supports `ViewComponentParentClasses` to configure additional base classes beyond `ViewComponent::Base` and `ApplicationComponent`:

```yaml
AllCops:
  ViewComponentParentClasses:
    - MyApp::BaseComponent
```

### Verification System

The `script/verify` script downloads real component libraries, runs all ViewComponent cops, and compares results to checked-in snapshots. This catches regressions when cop behavior changes. Libraries are configured in `verification/libraries.yml`, downloaded to `verification/LIBRARY/`, and expected results stored in `spec/expected_LIBRARY_failures.json`.

## Implementation Notes

- When adding a new cop, use `rake new_cop[ViewComponent/CopName]` to generate the boilerplate
- Template analysis is performance-sensitive - `PreferPrivateMethods` uses `herb` gem for efficient ERB parsing
- Cops must handle graceful degradation when templates can't be parsed
- All cops should include `ViewComponent::Base` module to get detection helpers
