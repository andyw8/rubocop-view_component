# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::TestRenderedOutput, :config do
  let(:config) { RuboCop::Config.new }

  context "when calling methods on a component variable" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        component = UserComponent.new("hello")
        component.formatted_title
        ^^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Avoid testing ViewComponent methods directly. Use `render_inline` and assert against rendered output instead.
      RUBY
    end
  end

  context "when calling methods inline on a component instance" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        UserComponent.new("hello").formatted_title
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Avoid testing ViewComponent methods directly. Use `render_inline` and assert against rendered output instead.
      RUBY
    end
  end

  context "when using render_inline" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        render_inline UserComponent.new("hello")
      RUBY
    end
  end

  context "when calling methods on non-component variables" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        user = User.new("hello")
        user.formatted_name
      RUBY
    end
  end

  context "when using reflection methods on a component" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        component = UserComponent.new("hello")
        component.is_a?(ViewComponent::Base)
      RUBY
    end
  end

  context "when calling methods on a namespaced component" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        component = Admin::UserComponent.new("hello")
        component.formatted_title
        ^^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Avoid testing ViewComponent methods directly. Use `render_inline` and assert against rendered output instead.
      RUBY
    end
  end
end
