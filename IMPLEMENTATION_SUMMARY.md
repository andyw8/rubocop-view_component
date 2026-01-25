# RuboCop ViewComponent Extension - Implementation Summary

## Overview

Successfully implemented Phase 1 of the RuboCop ViewComponent extension following a Test-Driven Development (TDD) approach. All 36 tests pass, and the cops are fully functional.

## Implemented Cops

### 1. ViewComponent/ComponentSuffix
**Purpose**: Enforces that ViewComponent classes end with the `Component` suffix.

**Severity**: Warning

**Example**:
```ruby
# bad
class FooBar < ViewComponent::Base
end

# good
class FooBarComponent < ViewComponent::Base
end
```

### 2. ViewComponent/NoGlobalState
**Purpose**: Prevents direct access to global state (params, request, session, cookies, flash) within ViewComponent classes.

**Severity**: Warning

**Detects**: Access to `params`, `request`, `session`, `cookies`, `flash`

**Example**:
```ruby
# bad
class UserComponent < ViewComponent::Base
  def admin?
    params[:admin]
  end
end

# good
class UserComponent < ViewComponent::Base
  def initialize(admin:)
    @admin = admin
  end

  def admin?
    @admin
  end
end
```

### 3. ViewComponent/PreferPrivateMethods
**Purpose**: Suggests making helper methods private in ViewComponents.

**Severity**: Convention

**Allowed Public Methods**: `initialize`, `call`, `before_render`, `before_render_check`, `render?`

**Example**:
```ruby
# bad
class CardComponent < ViewComponent::Base
  def formatted_title
    @title.upcase
  end
end

# good
class CardComponent < ViewComponent::Base
  private

  def formatted_title
    @title.upcase
  end
end
```

### 4. ViewComponent/PreferSlots
**Purpose**: Detects parameters that accept HTML content and suggests using slots instead.

**Severity**: Warning

**Detected Patterns**:
- Parameters ending with `_html`
- Parameters ending with `_content`
- Parameters starting with `html_` (except `html_class`, `html_classes`, `html_id`, `html_tag`)
- Parameters named `content`
- Parameters with `html_safe` default values

**Example**:
```ruby
# bad
class ModalComponent < ViewComponent::Base
  def initialize(title:, body_html:)
    @title = title
    @body_html = body_html
  end
end

# good
class ModalComponent < ViewComponent::Base
  renders_one :body

  def initialize(title:)
    @title = title
  end
end
```

## File Structure

### Core Files
- `lib/rubocop/cop/view_component/base.rb` - Shared helper methods
- `lib/rubocop/cop/view_component/component_suffix.rb` - ComponentSuffix cop
- `lib/rubocop/cop/view_component/no_global_state.rb` - NoGlobalState cop
- `lib/rubocop/cop/view_component/prefer_private_methods.rb` - PreferPrivateMethods cop
- `lib/rubocop/cop/view_component/prefer_slots.rb` - PreferSlots cop
- `lib/rubocop/cop/view_component_cops.rb` - Requires all cops
- `config/default.yml` - Cop configurations

### Test Files
- `spec/rubocop/cop/view_component/component_suffix_spec.rb` - 10 tests
- `spec/rubocop/cop/view_component/no_global_state_spec.rb` - 10 tests
- `spec/rubocop/cop/view_component/prefer_private_methods_spec.rb` - 8 tests
- `spec/rubocop/cop/view_component/prefer_slots_spec.rb` - 8 tests

## Test Results

```
36 examples, 0 failures
```

All cops are working correctly and detecting violations as expected.

## Verification

Successfully tested with a sample file containing multiple violations:

```ruby
class FooBar < ViewComponent::Base
  def initialize(title:, body_html:)
    @title = title
    @body_html = body_html
  end

  def helper_method
    params[:id]
  end
end
```

**Detected Violations**:
1. ComponentSuffix: Class name should end with `Component`
2. NoGlobalState: Avoid accessing `params` directly
3. PreferPrivateMethods: `helper_method` should be private
4. PreferSlots: `body_html:` should use slots instead

## Design Decisions

1. **No Auto-correction**: All cops are detection-only (no `extend AutoCorrector`)
2. **Module-based Architecture**: Shared helpers in `ViewComponent::Base` module
3. **ViewComponent 4.0+ Target**: Focused on modern ViewComponent patterns
4. **RSpec Testing Framework**: Using RuboCop's official testing support

## Next Steps (Future Phases)

Phase 1 is complete. Future phases could include:
- Additional cops for other ViewComponent best practices
- Auto-correction support for simpler violations
- Performance optimizations
- Integration with CI/CD pipelines
