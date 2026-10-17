# rubydex integration

This gem uses [rubydex](https://github.com/Shopify/rubydex), Shopify's high-performance
static analysis toolkit for Ruby, to answer questions that cannot be answered from a
single file's AST.

Most ViewComponent cops only care about *ancestry*: is this class (or the class it
inherits from) ultimately a `ViewComponent::Base` descendant? A class may inherit from
`ApplicationComponent`, which inherits from a gem's base class, which finally inherits
from `ViewComponent::Base` — none of which is visible in the file being inspected.
Resolving that chain requires a project-wide index, and that is what rubydex provides.

## How RuboCop exposes the index

RuboCop 1.89+ integrates rubydex behind an opt-in flag. This gem requires that
version (see `rubocop-view_component.gemspec`).

1. When `AllCops/UseProjectIndex` is `true`, RuboCop builds a resolved
   `Rubydex::Graph` for the whole project (`RuboCop::ProjectIndexLoader`).
2. The graph is exposed to cops through `RuboCop::Cop::Base#project_index`.
3. Cops that mix in `RuboCop::Cop::ProjectIndexHelp` also get an
   `external_dependency_checksum` override, which invalidates RuboCop's result cache
   whenever an indexed file changes on disk.

If the `rubydex` gem is not installed, or the running Ruby is older than 3.2, RuboCop
warns and degrades to file-local analysis (`project_index` is `nil`).

## How this gem uses it

`ViewComponent::Base` (`lib/rubocop/cop/view_component/base.rb`) includes
`ProjectIndexHelp` and queries the index through `resolve_constant_in_index`:

- `view_component_class?` — resolves a class's superclass expression and checks it.
- `view_component_parent?` — resolves a constant and calls
  `declaration.has_ancestor?("ViewComponent::Base")`.
- `view_component_parent_class?` — checks `has_ancestor?` plus `declaration.descendants`
  to detect abstract base classes that have their own subclasses in the project.
- `inside_view_component?` — finds the enclosing class and delegates to
  `view_component_class?`.

All of these call `require_project_index!` first, which raises with an actionable
message if the index is unavailable:

```
ViewComponent cops require `AllCops/UseProjectIndex: true` in your .rubocop.yml
for ancestry-based class detection.
```

The one exception is `ComponentNamespaces`: if a class's fully-qualified name matches a
configured namespace prefix, `view_component_class?` can return `true` without touching
the index, so projects that use explicit namespaces can avoid the requirement in that
specific case.

## Configuration

Enable the index in your `.rubocop.yml`:

```yaml
AllCops:
  UseProjectIndex: true
```

If your components inherit from a library (e.g. Primer) whose base class lives in a gem,
also enable gem indexing so the ancestry chain can be followed through the gem's source:

```yaml
AllCops:
  ProjectIndexIncludesGems: true
```

## Performance notes

- The index always covers the whole project (rooted at the directory of the config that
  enabled it), not just the files in the current run, so cross-file offenses are
  consistent between full runs, editor runs, and CI shards.
- `external_dependency_checksum` ties the result cache to the indexed files' mtimes and
  sizes, so a warm cache is reused until a relevant file changes.
- On Windows, parallel inspection is skipped when the index is enabled.

## Testing

Specs do not build a full RuboCop run. `spec/support/project_index_helpers.rb` builds a
`Rubydex::Graph` directly from a set of in-memory sources:

```ruby
graph = Rubydex::Graph.new
graph.index_source("file:///user_component.rb", source, "ruby")
graph.resolve
```

`ProjectIndexHelpers::LazyIndex` wraps the graph and lazily indexes the source under
inspection on first miss, mirroring how the real runner indexes every project file
(including the one being inspected). `spec_helper.rb` assigns this to each cop's
`project_index` before examples run.

The real-world verification suites (`verification/*_rubocop_config.yml`) set
`UseProjectIndex: true` so the cops are exercised through the actual RuboCop runner.

## Further reading

- rubydex repository: <https://github.com/Shopify/rubydex>
- Ruby API documentation: <https://shopify.github.io/rubydex/>
- "One engine, many tools — Introducing Rubydex":
  <https://railsatscale.com/2026-05-12-one-engine-many-tools/>
- RuboCop 1.89 project-wide analysis announcement:
  <https://metaredux.com/posts/2026/08/05/rubocop-1-89.html>
