# Implementation Plan: Fix PreferPrivateMethods False Positives

## Problem

The `ViewComponent/PreferPrivateMethods` cop currently generates false positives by flagging methods that are called from ERB templates. In ViewComponent, methods called from templates must remain public, otherwise they cause runtime errors.

## Solution Overview

Use the `herb` gem to parse ERB templates and extract method calls. Only flag public methods that are NOT called from the component's template(s).

## Implementation Steps

### 1. Add herb Dependency

**File:** `rubocop-view_component.gemspec`

- Add `spec.add_dependency "herb", "~> 0.1"` (check latest stable version)

### 2. Create Template Finder Helper

**File:** `lib/rubocop/cop/view_component/template_analyzer.rb` (new)

Create a module `TemplateAnalyzer` with:

```ruby
module TemplateAnalyzer
  # Find template file(s) for a component
  # Returns array of template file paths (can be empty)
  def template_paths_for(component_file_path)
    # Check for sibling template: same_name.html.erb
    # Check for sidecar template: same_name/same_name.html.erb
    # Handle variants: same_name.variant.html.erb
  end

  # Extract method calls from ERB template
  def extract_method_calls(template_path)
    # Use Herb.extract_ruby to get Ruby code
    # Parse Ruby code with RuboCop's parser
    # Traverse AST to find method calls (send nodes with nil receiver)
    # Return Set of method names (symbols)
  end
end
```

**Implementation details:**

- Use `File.exist?` to check for template files
- Handle both naming conventions (sibling and sidecar)
- Parse extracted Ruby code using `RuboCop::AST::ProcessedSource`
- Traverse AST to find `send` nodes with `nil` receiver (local method calls)
- Handle edge cases:
  - Missing template (component uses `call` method)
  - Multiple templates (variants)
  - Parse errors in template

### 3. Update PreferPrivateMethods Cop

**File:** `lib/rubocop/cop/view_component/prefer_private_methods.rb`

Modify the cop to:

1. Include `TemplateAnalyzer` module
2. In `check_public_methods`, find template paths using the component file path
3. Extract method calls from all templates
4. Skip offense if method is called from any template

```ruby
def check_public_methods(class_node)
  current_visibility = :public
  template_method_calls = methods_called_in_templates(class_node)

  class_node.body&.each_child_node do |child|
    # ... existing visibility tracking ...

    next unless child.def_type?
    next unless current_visibility == :public
    next if ALLOWED_PUBLIC_METHODS.include?(child.method_name)
    next if template_method_calls.include?(child.method_name)  # NEW

    add_offense(child)
  end
end

private

def methods_called_in_templates(class_node)
  component_path = processed_source.file_path
  template_paths = template_paths_for(component_path)

  template_paths.flat_map { |path| extract_method_calls(path) }.to_set
rescue => e
  # Log error and return empty set (graceful degradation)
  Set.new
end
```

### 4. Update Tests

**File:** `spec/rubocop/cop/view_component/prefer_private_methods_spec.rb`

Add new test contexts:

1. **Methods called from template should NOT be flagged**
   - Create fixture component + template
   - Method is public and called in template
   - Expect no offense

2. **Methods NOT called from template should be flagged**
   - Create fixture component + template
   - Method is public but not used in template
   - Expect offense

3. **Component without template**
   - Component has no template file
   - Should fall back to current behavior (flag all non-interface methods)

4. **Component with multiple templates (variants)**
   - Component has multiple template files
   - Method called in any template should not be flagged

5. **Template with parse errors**
   - Invalid ERB syntax
   - Should gracefully degrade (don't flag any methods)

**Fixture structure:**

```
spec/fixtures/components/
  example_component.rb
  example_component.html.erb
  variant_component.rb
  variant_component.html.erb
  variant_component.phone.html.erb
```

### 5. Handle Edge Cases

- **No template file**: Fall back to current behavior
- **Invalid ERB**: Catch parse errors, log warning, skip template analysis
- **Sidecar directories**: Check both naming conventions
- **Variants**: Find all variant templates (*.html.erb, *.phone.html.erb, etc.)
- **Conditional method calls**: `<%= foo if condition %>` - still counts as using `foo`
- **Method chains**: `<%= user.name %>` - only `user` is a method call, not `name`
- **Block parameters**: `<% items.each do |item| %>` - `item` is not a method

### 6. Documentation Updates

**File:** `README.md`

Update the PreferPrivateMethods cop description to mention:
- Now checks ERB templates for method usage
- Only flags methods not called from templates
- Requires templates to be in conventional locations

## Testing Strategy

1. Unit tests for `TemplateAnalyzer` methods
2. Integration tests for the full cop with fixtures
3. Manual testing on real ViewComponent codebases

## Potential Issues

1. **Performance**: Parsing templates for every component could be slow
   - Mitigation: Cache template analysis results

2. **Complex Ruby in ERB**: Nested blocks, conditionals, etc.
   - Mitigation: Robust AST traversal

3. **Dynamic method calls**: `send(:method_name)`, `public_send`, etc.
   - Limitation: Won't detect these (acceptable trade-off)

## Success Criteria

- False positive rate drops from ~1,363 to near zero on the reported codebase
- No new false negatives (methods that should be private but aren't flagged)
- Tests pass
- Performance acceptable (< 100ms per component)
