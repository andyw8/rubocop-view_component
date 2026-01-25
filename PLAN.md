# RuboCop ViewComponent - Implementation Plan

## Overview

This document outlines the plan for building `rubocop-view_component`, a RuboCop extension to enforce ViewComponent best practices based on the official [ViewComponent Best Practices](https://viewcomponent.org/best_practices.html).

## Research Summary

### Existing Work

**Primer ViewComponents** (GitHub's design system) has custom RuboCop cops for ViewComponent:
- Located at: `lib/rubocop/cop/primer/`
- Includes cops like `Primer/NoTagMemoize`
- Source: [Primer ViewComponents Linting Docs](https://github.com/primer/view_components/blob/main/docs/contributors/linting.md)
- Note: We will not inherit from their configuration, but can reference their implementation patterns

### Key Technologies

1. **RuboCop AST Processing**
   - Cops inherit from `RuboCop::Cop::Base`
   - Use `def_node_matcher` for declarative pattern matching
   - Hook into callbacks like `on_send`, `on_class`, `on_def`
   - Node patterns use syntax like `(send nil? :method_name)`
   - Reference: [RuboCop Node Pattern Docs](https://docs.rubocop.org/rubocop-ast/node_pattern.html)

2. **Testing ViewComponents**
   - Use `render_inline(Component.new)` in tests
   - Assert against rendered output, not instance methods
   - Slots defined with `renders_one`/`renders_many`
   - Reference: [ViewComponent Testing Guide](https://viewcomponent.org/guide/testing.html)

---

## Proposed Cops (Priority Order)

### Phase 1: High-Value, Easy to Implement

#### 1. `ViewComponent/ComponentSuffix`
**Priority:** HIGH
**Complexity:** LOW

**Description:**
Enforce that all ViewComponent classes end with the `-Component` suffix to follow Rails naming conventions.

**Detection Pattern:**
```ruby
# Bad
class FooBar < ViewComponent::Base
class UserCard < ApplicationComponent

# Good
class FooBarComponent < ViewComponent::Base
class UserCardComponent < ApplicationComponent
```

**Implementation:**
- Hook: `on_class`
- Node Pattern: `(class (const _ !/_Component$/) (const ...) ...)`
- Check if superclass is `ViewComponent::Base` or inherits from it
- Suggest renaming to include `Component` suffix

**Autocorrect:** No

---

#### 2. `ViewComponent/NoGlobalState`
**Priority:** HIGH
**Complexity:** MEDIUM

**Description:**
Prevent direct access to global state (`params`, `request`, `session`, `cookies`, `flash`) within components. These should be passed as constructor arguments.

**Detection Pattern:**
```ruby
# Bad
class UserComponent < ViewComponent::Base
  def initialize(user)
    @user = user
  end

  def admin?
    params[:admin] == "true"  # Direct access to params
  end

  def user_agent
    request.user_agent  # Direct access to request
  end
end

# Good
class UserComponent < ViewComponent::Base
  def initialize(user, admin: false)
    @user = user
    @admin = admin
  end

  def admin?
    @admin
  end
end
```

**Implementation:**
- Hook: `on_send`
- Node Pattern: `(send nil? {:params :request :session :cookies :flash})`
- Check if within a ViewComponent class context
- Suggest passing as initialization parameter

**Autocorrect:** No (requires refactoring)

**References:**
- [ViewComponent Best Practices - Avoid Global State](https://viewcomponent.org/best_practices.html)

---

#### 3. `ViewComponent/PreferPrivateMethods`
**Priority:** MEDIUM
**Complexity:** LOW

**Description:**
Suggest making helper methods private since they remain accessible in templates anyway. Only standard ViewComponent interface methods should be public.

**Detection Pattern:**
```ruby
# Bad
class CardComponent < ViewComponent::Base
  def initialize(title)
    @title = title
  end

  def formatted_title  # Should be private
    @title.upcase
  end
end

# Good
class CardComponent < ViewComponent::Base
  def initialize(title)
    @title = title
  end

  private

  def formatted_title
    @title.upcase
  end
end
```

**Implementation:**
- Hook: `on_def`
- Allowlist: `initialize`, `call`, `before_render`, `render?`
- Check visibility of other methods
- Suggest making non-interface methods private

**Autocorrect:** No

---

#### 4. `ViewComponent/PreferSlots`
**Priority:** MEDIUM
**Complexity:** MEDIUM

**Description:**
Detect parameters that accept HTML content and suggest using slots instead. This maintains Rails' HTML sanitization protections.

**Detection Pattern:**
```ruby
# Bad
class ModalComponent < ViewComponent::Base
  def initialize(title:, body_html:)  # HTML as string parameter
    @title = title
    @body_html = body_html
  end
end

# Usage (unsafe)
<%= render ModalComponent.new(
  title: "Alert",
  body_html: "<p>#{user_input}</p>".html_safe
) %>

# Good
class ModalComponent < ViewComponent::Base
  renders_one :body

  def initialize(title:)
    @title = title
  end
end

# Usage (safe)
<%= render ModalComponent.new(title: "Alert") do |c| %>
  <% c.with_body do %>
    <p><%= user_input %></p>
  <% end %>
<% end %>
```

**Implementation:**
- Hook: `on_def` (check `initialize` method)
- Look for parameters ending in `_html`, `_content`, or types suggesting HTML
- Look for `.html_safe` calls in parameter defaults
- Suggest using `renders_one` or `renders_many` instead

**Autocorrect:** No (requires refactoring)

**Security Impact:** HIGH - prevents XSS vulnerabilities

**References:**
- [ViewComponent Best Practices - Prefer Slots Over HTML Arguments](https://viewcomponent.org/best_practices.html)
- [ViewComponent Slots Guide](https://viewcomponent.org/guide/slots.html)

---

### Phase 2: Architectural Quality

#### 5. `ViewComponent/PreferComposition`
**Priority:** MEDIUM
**Complexity:** MEDIUM

**Description:**
Detect inheritance chains deeper than one level and suggest composition instead. Inheriting one component from another causes confusion when each has its own template.

**Detection Pattern:**
```ruby
# Bad
class BaseCard < ViewComponent::Base
  # template: base_card.html.erb
end

class UserCard < BaseCard  # Inheritance from another component
  # template: user_card.html.erb - confusing!
end

# Good
class UserCardComponent < ViewComponent::Base
  def initialize(user)
    @user = user
  end

  # Render BaseCardComponent within template via composition
end
```

**Implementation:**
- Hook: `on_class`
- Track inheritance chain depth
- Detect if superclass is a ViewComponent (not `ViewComponent::Base` or `ApplicationComponent`)
- Suggest wrapping pattern instead

**Autocorrect:** No (requires architectural refactoring)

**References:**
- [ViewComponent Best Practices - Composition Over Inheritance](https://viewcomponent.org/best_practices.html)

---

#### 6. `ViewComponent/AvoidSingleUseComponents`
**Priority:** LOW
**Complexity:** MEDIUM

**Description:**
Detect components that appear to be single-use (no methods, no slots, minimal logic) and suggest reconsidering if the component adds value over a partial.

**Detection Pattern:**
```ruby
# Questionable
class SimpleWrapperComponent < ViewComponent::Base
  def initialize(content)
    @content = content
  end
  # No other methods, no slots, no logic
end

# Better as partial or inline template
```

**Implementation:**
- Hook: `on_class`
- Analyze class body for:
  - Number of instance methods (beyond `initialize`)
  - Presence of slots (`renders_one`, `renders_many`)
  - Complexity of logic
- Provide informational warning if component seems trivial

**Autocorrect:** No

**Severity:** Information (not error)

**References:**
- [ViewComponent Best Practices - Minimize One-Offs](https://viewcomponent.org/best_practices.html)

---

### Phase 3: Testing Best Practices

#### 7. `ViewComponent/TestRenderedOutput`
**Priority:** MEDIUM
**Complexity:** MEDIUM

**Description:**
In test files, detect assertions against component instance methods and suggest using `render_inline` with content assertions instead.

**Detection Pattern:**
```ruby
# Bad
test "formats title" do
  component = TitleComponent.new("hello")
  assert_equal "HELLO", component.formatted_title  # Testing private method
end

# Good
test "renders formatted title" do
  render_inline TitleComponent.new("hello")
  assert_text "HELLO"
end
```

**Implementation:**
- Hook: `on_send`
- Context: Within test files (`*_test.rb`, `*_spec.rb`)
- Detect: Method calls on component instances (not `render_inline` results)
- Suggest: Using `render_inline` and asserting against rendered output

**Autocorrect:** No

**References:**
- [ViewComponent Best Practices - Test Rendered Output](https://viewcomponent.org/best_practices.html)
- [ViewComponent Testing Guide](https://viewcomponent.org/guide/testing.html)

---


## Technical Architecture

### Directory Structure

```
lib/
├── rubocop/
│   ├── cop/
│   │   ├── view_component_cops.rb          # Requires all cops
│   │   └── view_component/
│   │       ├── component_suffix.rb
│   │       ├── no_global_state.rb
│   │       ├── prefer_private_methods.rb
│   │       ├── prefer_slots.rb
│   │       ├── prefer_composition.rb
│   │       ├── avoid_single_use_components.rb
│   │       └── test_rendered_output.rb
│   └── view_component/
│       ├── version.rb
│       ├── plugin.rb
│       └── inject.rb                       # Config injection
├── rubocop-view_component.rb
config/
└── default.yml                              # Default cop configuration
spec/
└── rubocop/
    └── cop/
        └── view_component/
            ├── component_suffix_spec.rb
            └── ...
```

### Cop Template

Each cop should follow this structure:

```ruby
# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Enforces [best practice name].
      #
      # @example
      #   # bad
      #   [bad code example]
      #
      #   # good
      #   [good code example]
      #
      class CopName < Base
        MSG = 'Explain the problem and suggest solution.'
        RESTRICT_ON_SEND = %i[method_name].freeze  # Optional optimization

        def_node_matcher :pattern_name, <<~PATTERN
          (send ...)
        PATTERN

        def on_send(node)
          return unless pattern_name(node)
          # Check conditions

          add_offense(node)
        end

        private

        def in_view_component?(node)
          # Helper to check if within ViewComponent class
        end
      end
    end
  end
end
```

### Configuration (config/default.yml)

```yaml
ViewComponent/ComponentSuffix:
  Description: 'Enforce -Component suffix for ViewComponent classes.'
  Enabled: true
  VersionAdded: '0.1'
  Severity: warning

ViewComponent/NoGlobalState:
  Description: 'Avoid accessing global state (params, request, session, etc.) directly.'
  Enabled: true
  VersionAdded: '0.1'
  Severity: warning

ViewComponent/PreferPrivateMethods:
  Description: 'Suggest making helper methods private.'
  Enabled: true
  VersionAdded: '0.1'
  Severity: convention
  AllowedPublicMethods:
    - initialize
    - call
    - before_render
    - render?

# ... etc
```

### Helper Modules

Create shared utilities:

```ruby
# lib/rubocop/cop/view_component/helpers.rb
module RuboCop
  module Cop
    module ViewComponent
      module Helpers
        def view_component_class?(node)
          # Check if node is within a ViewComponent class
        end

        def inherits_from_view_component?(class_node)
          # Check inheritance chain
        end
      end
    end
  end
end
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Set up proper gem structure with lint_roller integration
- [ ] Create base helper modules
- [ ] Implement `ComponentSuffix` cop
- [ ] Implement `NoGlobalState` cop
- [ ] Write comprehensive tests for Phase 1 cops
- [ ] Update default.yml configuration

### Phase 2: Core Best Practices (Week 3-4)
- [ ] Implement `PreferPrivateMethods` cop
- [ ] Implement `PreferSlots` cop
- [ ] Implement `PreferComposition` cop
- [ ] Documentation and examples

### Phase 3: Testing & Quality (Week 5-6)
- [ ] Implement `TestRenderedOutput` cop
- [ ] Implement `AvoidSingleUseComponents` cop
- [ ] Add performance optimizations
- [ ] Integration testing with real-world ViewComponent projects
- [ ] Performance benchmarking
- [ ] Documentation site

---

## Testing Strategy

### Cop Testing
Each cop should have:

1. **Positive cases** - Code that triggers the offense
2. **Negative cases** - Code that should not trigger
3. **Edge cases** - Boundary conditions

Example test structure:
```ruby
RSpec.describe RuboCop::Cop::ViewComponent::NoGlobalState, :config do
  it 'registers an offense when accessing params' do
    expect_offense(<<~RUBY)
      class MyComponent < ViewComponent::Base
        def admin?
          params[:admin]
          ^^^^^^ Avoid accessing global state directly. Pass as initialization parameter.
        end
      end
    RUBY
  end

  it 'does not register offense for instance variables' do
    expect_no_offenses(<<~RUBY)
      class MyComponent < ViewComponent::Base
        def initialize(admin:)
          @admin = admin
        end

        def admin?
          @admin
        end
      end
    RUBY
  end
end
```

### Integration Testing
- Integration testing with fixture ViewComponent projects

---

## Documentation Plan

### README.md Updates
- Clear installation instructions
- Quick start guide
- List of all cops with examples
- Configuration options
- Integration with CI/CD

### Individual Cop Documentation
Each cop should have:
- Clear description
- Why it exists (reference to best practice)
- Bad/good code examples
- Configuration options

---

## Future Enhancements

### Potential Additional Cops

1. **`ViewComponent/MinimizeTemplateLogic`**
   - Detect complex Ruby logic in `.html.erb` templates
   - Suggest extracting to component methods
   - **Challenge:** Requires parsing ERB templates
   - Reference: [ViewComponent Best Practices - Minimize Template Logic](https://viewcomponent.org/best_practices.html)

2. **`ViewComponent/NoQueryInComponent`**
   - Detect ActiveRecord queries in components
   - Components should receive data, not fetch it

3. **`ViewComponent/PreferStrictLocals`**
   - Encourage use of `locals` declaration in templates
   - Catches typos and documents component API

4. **`ViewComponent/SlotNamingConvention`**
   - Enforce naming conventions for slots
   - Singular for `renders_one`, plural for `renders_many`

5. **`ViewComponent/NoControllerHelpers`**
   - Detect usage of controller-specific helpers
   - Promotes reusability


## References & Resources

### Official Documentation
- [ViewComponent Best Practices](https://viewcomponent.org/best_practices.html)
- [ViewComponent Testing Guide](https://viewcomponent.org/guide/testing.html)
- [ViewComponent Slots Guide](https://viewcomponent.org/guide/slots.html)
- [RuboCop Development Guide](https://docs.rubocop.org/rubocop/development.html)
- [RuboCop Node Patterns](https://docs.rubocop.org/rubocop-ast/node_pattern.html)

### Community Resources
- [Custom Cops for RuboCop - Evil Martians](https://evilmartians.com/chronicles/custom-cops-for-rubocop-an-emergency-service-for-your-codebase)
- [Create a Custom RuboCop Cop - FastRuby.io](https://www.fastruby.io/blog/rubocop/code-quality/create-a-custom-rubocop-cop.html)
- [Thoughtbot - Custom Cops](https://thoughtbot.com/blog/rubocop-custom-cops-for-custom-needs)
- [RuboCop RSpec Cops](https://docs.rubocop.org/rubocop-rspec/cops_rspec.html)
- [Shopify ERB Lint](https://github.com/Shopify/erb_lint)

### Similar Projects
- [rubocop-rails](https://github.com/rubocop/rubocop-rails)
- [rubocop-rspec](https://github.com/rubocop/rubocop-rspec)
- [Primer ViewComponents](https://github.com/primer/view_components) - Has custom cops

### ViewComponent Anti-Patterns
- [ViewComponent Tips](https://railsnotes.xyz/blog/rails-viewcomponent-tips)
- [Advanced ViewComponent Patterns](https://dev.to/abeidahmed/advanced-viewcomponent-patterns-in-rails-2b4m)
- [ViewComponent in the Wild - Evil Martians](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-building-modern-rails-frontends)

---

## Next Steps

1. **Review this plan** with stakeholders/community
2. **Set up development environment** with proper test fixtures
3. **Start with Phase 1** - implement high-value, low-complexity cops first
4. **Get early feedback** from ViewComponent users
5. **Iterate based on real-world usage**

---

## Questions to Resolve

1. Should we support legacy ViewComponent versions (< 3.0)? **NO** - Only support ViewComponent 3.0+
2. How to handle custom base classes (e.g., `ApplicationComponent`)? **TBD** - Discuss later
3. Should we integrate with erb-lint or keep separate? **SEPARATE** - Keep as separate tool
4. What's the policy on autocorrect? **NO AUTOCORRECT** - Detection only, no automatic fixes
5. Should we coordinate with Primer ViewComponents team to avoid duplication? **NO** - Independent project
