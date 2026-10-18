# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::TestRenderedOutput, :config do
  include ViewComponent::ProjectIndexHelpers

  let(:config) { RuboCop::Config.new }
  let(:project_index) { build_index }

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

    context "when test instantiates a non-Component-suffixed class" do
      it "registers an offense for an indexed component" do
        expect_offense(<<~RUBY)
          def test_toggle
          ^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
            component = UserComponent.new
            assert component.active?
          end
        RUBY
      end
    end

    context "when test instantiates a non-ViewComponent value object" do
      let(:project_index) do
        build_index(
          "file:///month.rb" => <<~RUBY
            class Month
            end
          RUBY
        )
      end

      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_month
            month = Month.new
            assert month.active?
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

    context "when test instantiates a component and uses render_in_view_context" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_form_input
            render_in_view_context do
              render(UserComponent.new("hello"))
            end
          end
        RUBY
      end
    end

    context "when test doesn't instantiate any constants" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_helper_method
            result = some_method("hello")
            assert_equal "HELLO", result
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
      it "registers an offense for an indexed component" do
        expect_offense(<<~RUBY)
          def test_namespaced
          ^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
            component = UserComponent.new("hello")
            assert_equal "HELLO", component.formatted_title
          end
        RUBY
      end
    end

    context "when the component is built to assert an error" do
      it "does not register an offense for assert_raises" do
        expect_no_offenses(<<~RUBY)
          def test_raises_for_invalid_input
            assert_raises(ArgumentError) { UserComponent.new(nil) }
          end
        RUBY
      end

      it "does not register an offense for a do/end assert_raises block" do
        expect_no_offenses(<<~RUBY)
          def test_raises_for_invalid_input
            assert_raises(ArgumentError) do
              UserComponent.new(nil)
            end
          end
        RUBY
      end

      it "registers an offense when a component is built outside the assertion" do
        expect_offense(<<~RUBY)
          def test_mixed
          ^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
            component = UserComponent.new("hello")
            assert_raises(ArgumentError) { component.invalid! }
          end
        RUBY
      end
    end
  end

  context "with TestPaths configured" do
    let(:config) do
      RuboCop::Config.new(
        "AllCops" => { "DisplayCopNames" => true },
        "ViewComponent/TestRenderedOutput" => {
          "TestPaths" => ["spec/components/v2/"]
        }
      )
    end

    context "when file is within a configured TestPath" do
      it "registers an offense" do
        expect_offense(<<~RUBY, "spec/components/v2/button_component_spec.rb")
          def test_formatted_title
          ^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
            component = UserComponent.new("hello")
            assert_equal "HELLO", component.formatted_title
          end
        RUBY
      end
    end

    context "when file is outside all configured TestPaths" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY, "spec/components/v1/button_component_spec.rb")
          def test_formatted_title
            component = UserComponent.new("hello")
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

    context "when it block instantiates a component and uses render_in_view_context" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          it "renders a form" do
            render_in_view_context do
              render(UserComponent.new("hello"))
            end
          end
        RUBY
      end
    end

    context "when it block doesn't instantiate components" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          it "formats the name" do
            result = some_method("hello")
            expect(result).to eq("HELLO")
          end
        RUBY
      end
    end

    context "when it block uses described_class inside a describe block" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe UserComponent do
            it "formats the title" do
            ^^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
              component = described_class.new("hello")
              expect(component.formatted_title).to eq("HELLO")
            end
          end
        RUBY
      end

      it "registers an offense for RSpec.describe" do
        expect_offense(<<~RUBY)
          RSpec.describe UserComponent do
            it "formats the title" do
            ^^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
              expect(described_class.new("hello").formatted_title).to eq("HELLO")
            end
          end
        RUBY
      end

      it "registers an offense inside a nested context" do
        expect_offense(<<~RUBY)
          describe UserComponent do
            context "when rendered" do
              it "formats the title" do
              ^^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
                component = described_class.new("hello")
                expect(component.formatted_title).to eq("HELLO")
              end
            end
          end
        RUBY
      end

      it "does not register an offense when using render_inline" do
        expect_no_offenses(<<~RUBY)
          describe UserComponent do
            it "formats the title" do
              render_inline described_class.new("hello")
              expect(page).to have_text("HELLO")
            end
          end
        RUBY
      end
    end

    context "when the component is built to assert an error" do
      it "does not register an offense for described_class" do
        expect_no_offenses(<<~RUBY)
          describe UserComponent do
            it "raises for invalid input" do
              expect { described_class.new(nil) }.to raise_error(ArgumentError)
            end
          end
        RUBY
      end

      it "does not register an offense for a component constant" do
        expect_no_offenses(<<~RUBY)
          it "raises for invalid input" do
            expect { UserComponent.new(nil) }.to raise_error(ArgumentError)
          end
        RUBY
      end

      it "does not register an offense for not_to raise_error" do
        expect_no_offenses(<<~RUBY)
          it "does not raise for valid input" do
            expect { UserComponent.new("hello") }.not_to raise_error
          end
        RUBY
      end

      it "does not register an offense when raise_error takes a block" do
        expect_no_offenses(<<~RUBY)
          it "raises with a message" do
            expect { UserComponent.new(nil) }.to raise_error(ArgumentError) do |error|
              expect(error.message).to eq("invalid")
            end
          end
        RUBY
      end
    end

    context "when a component is built by a let helper" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe UserComponent do
            let(:component) { UserComponent.new("hello") }

            it "formats the title" do
            ^^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
              expect(component.formatted_title).to eq("HELLO")
            end
          end
        RUBY
      end

      it "registers an offense for a subject using described_class" do
        expect_offense(<<~RUBY)
          describe UserComponent do
            subject(:component) { described_class.new("hello") }

            it "formats the title" do
            ^^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
              expect(component.formatted_title).to eq("HELLO")
            end
          end
        RUBY
      end

      it "registers an offense when the let is defined in an outer group" do
        expect_offense(<<~RUBY)
          describe UserComponent do
            let(:component) { UserComponent.new("hello") }

            context "when rendered" do
              it "formats the title" do
              ^^^^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/TestRenderedOutput: Test instantiates a component but doesn't use `render_inline` or `render_preview`. Test the rendered output instead of component methods directly.
                expect(component.formatted_title).to eq("HELLO")
              end
            end
          end
        RUBY
      end

      it "does not register an offense when the helper renders output" do
        expect_no_offenses(<<~RUBY)
          describe UserComponent do
            let(:rendered) { render_inline(UserComponent.new("hello")) }

            it "formats the title" do
              expect(rendered).to have_text("HELLO")
            end
          end
        RUBY
      end

      it "does not register an offense when the helper builds another object" do
        expect_no_offenses(<<~RUBY)
          describe UserComponent do
            let(:component) { double("component") }

            it "formats the title" do
              expect(component.formatted_title).to eq("HELLO")
            end
          end
        RUBY
      end

      it "does not register an offense when the helper is rendered with render_inline" do
        expect_no_offenses(<<~RUBY)
          describe UserComponent do
            let(:component) { UserComponent.new("hello") }

            it "formats the title" do
              render_inline(component)
              expect(page).to have_text("HELLO")
            end
          end
        RUBY
      end

      it "prefers the innermost helper definition" do
        expect_no_offenses(<<~RUBY)
          describe UserComponent do
            let(:component) { UserComponent.new("hello") }

            context "with a stub" do
              let(:component) { double("component") }

              it "formats the title" do
                expect(component).to be_present
              end
            end
          end
        RUBY
      end
    end
  end

  context "when the described class is not a ViewComponent" do
    let(:project_index) do
      build_index(
        "file:///month.rb" => <<~RUBY
          class Month
          end
        RUBY
      )
    end

    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        describe Month do
          it "formats the month" do
            month = described_class.new
            expect(month.active?).to be(true)
          end
        end
      RUBY
    end
  end
end
