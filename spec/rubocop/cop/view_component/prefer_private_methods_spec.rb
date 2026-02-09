# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::PreferPrivateMethods, :config do
  let(:config) { RuboCop::Config.new }

  context "when component has public helper methods" do
    it "registers offense for public helper method" do
      expect_offense(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def initialize(title)
            @title = title
          end

          def formatted_title
          ^^^^^^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making `formatted_title` private. Only ViewComponent interface methods should be public.
            @title.upcase
          end
        end
      RUBY
    end

    it "registers offense for multiple public helpers" do
      expect_offense(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def helper_one
          ^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making `helper_one` private. Only ViewComponent interface methods should be public.
            'one'
          end

          def helper_two
          ^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making `helper_two` private. Only ViewComponent interface methods should be public.
            'two'
          end
        end
      RUBY
    end
  end

  context "when helper methods are already private" do
    it "does not register offense" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def initialize(title)
            @title = title
          end

          private

          def formatted_title
            @title.upcase
          end
        end
      RUBY
    end
  end

  context "with allowed public interface methods" do
    it "allows initialize" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def initialize(title)
            @title = title
          end
        end
      RUBY
    end

    it "allows call" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def call
            'rendered'
          end
        end
      RUBY
    end

    it "allows before_render" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def before_render
            @computed = true
          end
        end
      RUBY
    end

    it "allows before_render_check" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def before_render_check
            raise "invalid" unless @valid
          end
        end
      RUBY
    end

    it "allows render?" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def render?
            @show
          end
        end
      RUBY
    end

    it "allows render_in" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def render_in(view_context, &block)
            super
          end
        end
      RUBY
    end

    it "allows around_render" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def around_render
            yield
          end
        end
      RUBY
    end
  end

  context "with AllowedPublicMethodPatterns" do
    it "allows with_* slot builder methods by default" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def with_header(text)
            @header = text
          end

          def with_footer(text)
            @footer = text
          end
        end
      RUBY
    end

    context "with custom patterns" do
      let(:config) do
        RuboCop::Config.new(
          "AllCops" => {"DisplayCopNames" => true},
          "ViewComponent/PreferPrivateMethods" => {
            "AllowedPublicMethods" => %w[initialize call],
            "AllowedPublicMethodPatterns" => ["^render_", "^with_"]
          }
        )
      end

      it "allows methods matching custom patterns" do
        expect_no_offenses(<<~RUBY)
          class CardComponent < ViewComponent::Base
            def render_header
              'header'
            end

            def with_title(text)
              @title = text
            end
          end
        RUBY
      end

      it "still flags methods not matching any pattern" do
        expect_offense(<<~RUBY)
          class CardComponent < ViewComponent::Base
            def initialize(title)
              @title = title
            end

            def formatted_title
            ^^^^^^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making `formatted_title` private. Only ViewComponent interface methods should be public.
              @title.upcase
            end
          end
        RUBY
      end
    end
  end

  context "with custom AllowedPublicMethods" do
    let(:config) do
      RuboCop::Config.new(
        "AllCops" => {"DisplayCopNames" => true},
        "ViewComponent/PreferPrivateMethods" => {
          "AllowedPublicMethods" => %w[initialize call custom_public_method],
          "AllowedPublicMethodPatterns" => []
        }
      )
    end

    it "allows custom configured public methods" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def custom_public_method
            'custom'
          end
        end
      RUBY
    end

    it "flags methods not in custom allowlist" do
      expect_offense(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def initialize(title)
            @title = title
          end

          def other_method
          ^^^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making `other_method` private. Only ViewComponent interface methods should be public.
            'other'
          end
        end
      RUBY
    end
  end

  context "with mixed visibility" do
    it "only flags public methods" do
      expect_offense(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def public_helper
          ^^^^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making `public_helper` private. Only ViewComponent interface methods should be public.
            'public'
          end

          private

          def private_helper
            'private'
          end

          public

          def another_public
          ^^^^^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making `another_public` private. Only ViewComponent interface methods should be public.
            'public'
          end
        end
      RUBY
    end
  end

  context "when not a ViewComponent" do
    it "does not register offense" do
      expect_no_offenses(<<~RUBY)
        class RegularClass
          def public_method
            'public'
          end
        end
      RUBY
    end
  end

  context "with template files" do
    let(:component_file) { "spec/fixtures/components/template_method_component.rb" }

    it "does not flag methods called in template, but flags unused methods" do
      expect_offense(<<~RUBY, component_file)
        # frozen_string_literal: true

        class TemplateMethodComponent < ViewComponent::Base
          def initialize(title)
            @title = title
          end

          def formatted_title
            @title.upcase
          end

          def helper_not_used
          ^^^^^^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making `helper_not_used` private. Only ViewComponent interface methods should be public.
            "not used"
          end
        end
      RUBY
    end

    it "allows all public methods when they are all used in template" do
      expect_no_offenses(<<~RUBY, component_file)
        class CardComponent < ViewComponent::Base
          def initialize(title)
            @title = title
          end

          def call
            'rendered'
          end
        end
      RUBY
    end
  end
end
