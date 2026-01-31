# frozen_string_literal: true

require "tmpdir"

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
          ^^^^^^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making this method private. Only ViewComponent interface methods should be public.
            @title.upcase
          end
        end
      RUBY
    end

    it "registers offense for multiple public helpers" do
      expect_offense(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def helper_one
          ^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making this method private. Only ViewComponent interface methods should be public.
            'one'
          end

          def helper_two
          ^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making this method private. Only ViewComponent interface methods should be public.
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

    it "allows render?" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def render?
            @show
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
          ^^^^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making this method private. Only ViewComponent interface methods should be public.
            'public'
          end

          private

          def private_helper
            'private'
          end

          public

          def another_public
          ^^^^^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making this method private. Only ViewComponent interface methods should be public.
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
    around do |example|
      Dir.mktmpdir do |tmpdir|
        @tmpdir = tmpdir
        example.run
      end
    end

    it "does not flag methods called in template, but flags unused methods" do
      component_path = File.join(@tmpdir, "example_component.rb")
      template_path = File.join(@tmpdir, "example_component.html.erb")

      # Create template file that calls formatted_title
      File.write(template_path, <<~ERB)
        <div class="card">
          <h1><%= formatted_title %></h1>
        </div>
      ERB

      # Create component file
      File.write(component_path, <<~RUBY)
        # frozen_string_literal: true

        class ExampleComponent < ViewComponent::Base
          def initialize(title)
            @title = title
          end

          def formatted_title
            @title.upcase
          end

          def helper_not_used
            "not used"
          end
        end
      RUBY

      expect_offense(<<~RUBY, component_path)
        # frozen_string_literal: true

        class ExampleComponent < ViewComponent::Base
          def initialize(title)
            @title = title
          end

          def formatted_title
            @title.upcase
          end

          def helper_not_used
          ^^^^^^^^^^^^^^^^^^^ ViewComponent/PreferPrivateMethods: Consider making this method private. Only ViewComponent interface methods should be public.
            "not used"
          end
        end
      RUBY
    end

    it "allows all public methods when all are ViewComponent interface methods" do
      component_path = File.join(@tmpdir, "card_component.rb")

      # No template file needed for this test
      File.write(component_path, <<~RUBY)
        class CardComponent < ViewComponent::Base
          def initialize(title)
            @title = title
          end

          def call
            'rendered'
          end
        end
      RUBY

      expect_no_offenses(<<~RUBY, component_path)
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
