# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::UseWithRequestUrl, :config do
  let(:config) { RuboCop::Config.new }

  context "with Minitest-style tests" do
    context "when a _path helper is used without with_request_url" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def test_link
            render_inline MyComponent.new
            assert_selector "a[href='\#{root_path}']"
                                       ^^^^^^^^^ ViewComponent/UseWithRequestUrl: Wrap the render in `with_request_url` when using URL helpers in a component test.
          end
        RUBY
      end
    end

    context "when a _url helper is used without with_request_url" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def test_link
            render_inline MyComponent.new
            assert_selector "a[href='\#{root_url}']"
                                       ^^^^^^^^ ViewComponent/UseWithRequestUrl: Wrap the render in `with_request_url` when using URL helpers in a component test.
          end
        RUBY
      end
    end

    context "when a _path helper is used with with_request_url" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_link
            with_request_url "/" do
              render_inline MyComponent.new
              assert_selector "a[href='\#{root_path}']"
            end
          end
        RUBY
      end
    end

    context "when a _path helper is used but no render method is present" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_link
            assert_selector "a[href='\#{root_path}']"
          end
        RUBY
      end
    end

    context "when no URL helpers are used" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_label
            render_inline MyComponent.new
            assert_text "Hello"
          end
        RUBY
      end
    end

    context "when method doesn't start with test_" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def helper_method
            render_inline MyComponent.new
            root_path
          end
        RUBY
      end
    end

    context "when _path is called on an explicit receiver" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def test_link
            render_inline MyComponent.new
            assert_selector "a[href='\#{routes.root_path}']"
          end
        RUBY
      end
    end

    context "when render_preview is used with a URL helper" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def test_preview
            render_preview(:default)
            assert_selector "a[href='\#{root_path}']"
                                       ^^^^^^^^^ ViewComponent/UseWithRequestUrl: Wrap the render in `with_request_url` when using URL helpers in a component test.
          end
        RUBY
      end
    end
  end

  context "with RSpec-style tests" do
    context "when a _path helper is used without with_request_url" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          it "renders a link" do
            render_inline MyComponent.new
            expect(page).to have_selector("a[href='\#{root_path}']")
                                                     ^^^^^^^^^ ViewComponent/UseWithRequestUrl: Wrap the render in `with_request_url` when using URL helpers in a component test.
          end
        RUBY
      end
    end

    context "when a _path helper is used with with_request_url" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          it "renders a link" do
            with_request_url "/" do
              render_inline MyComponent.new
              expect(page).to have_selector("a[href='\#{root_path}']")
            end
          end
        RUBY
      end
    end

    context "when no URL helpers are used" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          it "renders a label" do
            render_inline MyComponent.new
            expect(page).to have_text("Hello")
          end
        RUBY
      end
    end

    context "when a namespaced _path helper is used" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          it "renders a link" do
            render_inline MyComponent.new
            expect(page).to have_selector("a[href='\#{admin_users_path}']")
                                                     ^^^^^^^^^^^^^^^^ ViewComponent/UseWithRequestUrl: Wrap the render in `with_request_url` when using URL helpers in a component test.
          end
        RUBY
      end
    end
  end

  context "with IgnoredMethods configured" do
    let(:config) do
      RuboCop::Config.new(
        "AllCops" => { "DisplayCopNames" => true },
        "ViewComponent/UseWithRequestUrl" => { "Enabled" => true, "IgnoredMethods" => ["homepage_url"] }
      )
    end

    it "does not register an offense for an ignored method" do
      expect_no_offenses(<<~RUBY)
        it "renders a link" do
          render_inline MyComponent.new
          expect(rendered_content).to have_tag("a", href: homepage_url)
        end
      RUBY
    end

    it "still registers an offense for non-ignored URL helpers" do
      expect_offense(<<~RUBY)
        it "renders a link" do
          render_inline MyComponent.new
          expect(page).to have_selector("a[href='\#{root_path}']")
                                                   ^^^^^^^^^ ViewComponent/UseWithRequestUrl: Wrap the render in `with_request_url` when using URL helpers in a component test.
        end
      RUBY
    end
  end
end
