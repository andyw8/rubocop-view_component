# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::TestRenderedOutput, :config do
  let(:config) { RuboCop::Config.new }

  context "with Minitest-style tests" do
    context "when test instantiates a component but doesn't render" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def test_formatted_title
          ^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
            component = UserComponent.new("hello")
            assert_equal "HELLO", component.formatted_title
          end
        RUBY
      end
    end

    context "when test instantiates a component and uses render_inline" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_formatted_title
            render_inline UserComponent.new("hello")
            assert_text "HELLO"
          end
        RUBY
      end
    end

    context "when test instantiates a component and uses render_preview" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_preview
            render_preview(:default)
            assert_selector ".component"
          end
        RUBY
      end
    end

    context "when test doesn't instantiate any components" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_helper_method
            user = User.new("hello")
            assert_equal "HELLO", user.formatted_name
          end
        RUBY
      end
    end

    context "when test uses with_ configuration methods" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_with_content
            render_inline(UserComponent.new.with_content("Button"))
            assert_text "Button"
          end
        RUBY
      end
    end

    context "when method doesn't start with test_" do
      it "does not register an offense even with component instantiation" do
        expect_no_offenses(<<~RUBY)
          def helper_method
            component = UserComponent.new("hello")
            component.formatted_title
          end
        RUBY
      end
    end

    context "when test instantiates a namespaced component" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def test_namespaced
          ^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
            component = Admin::UserComponent.new("hello")
            assert_equal "HELLO", component.formatted_title
          end
        RUBY
      end
    end
  end

  context "with RSpec-style tests" do
    context "when it block instantiates a component but doesn't render" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          it "formats the title" do
          ^^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
            component = UserComponent.new("hello")
            expect(component.formatted_title).to eq("HELLO")
          end
        RUBY
      end
    end

    context "when it block instantiates a component and uses render_inline" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          it "formats the title" do
            render_inline UserComponent.new("hello")
            expect(page).to have_text("HELLO")
          end
        RUBY
      end
    end

    context "when it block doesn't instantiate components" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          it "formats the name" do
            user = User.new("hello")
            expect(user.formatted_name).to eq("HELLO")
          end
        RUBY
      end
    end
  end
end
