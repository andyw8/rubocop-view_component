# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::PreferComposition, :config do
  let(:config) { RuboCop::Config.new }

  context "when inheriting from another component" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        class UserCard < BaseCardComponent
                         ^^^^^^^^^^^^^^^^^ ViewComponent/PreferComposition: Avoid inheriting from another ViewComponent.
        end
      RUBY
    end

    it "registers an offense for namespaced component parent" do
      expect_offense(<<~RUBY)
        class UserCard < Admin::CardComponent
                         ^^^^^^^^^^^^^^^^^^^^ ViewComponent/PreferComposition: Avoid inheriting from another ViewComponent.
        end
      RUBY
    end
  end

  context "when inheriting from ViewComponent::Base" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class UserCardComponent < ViewComponent::Base
        end
      RUBY
    end
  end

  context "when inheriting from ApplicationComponent" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class UserCardComponent < ApplicationComponent
        end
      RUBY
    end
  end

  context "when inheriting from a non-component class" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class UserCard < ActiveRecord::Base
        end
      RUBY
    end

    it "does not register an offense for plain classes" do
      expect_no_offenses(<<~RUBY)
        class UserCard < SomeOtherBase
        end
      RUBY
    end
  end

  context "when the parent is a resolvable component with its own template" do
    it "registers an offense" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/test_source.html.erb").and_return(true)

      expect_offense(<<~RUBY)
        class BaseCardComponent < ViewComponent::Base
        end

        class UserCardComponent < BaseCardComponent
                                  ^^^^^^^^^^^^^^^^^ ViewComponent/PreferComposition: Avoid inheriting from another ViewComponent.
        end
      RUBY
    end
  end

  context "when the parent is a resolvable component without a template" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class BaseCardComponent < ViewComponent::Base
        end

        class UserCardComponent < BaseCardComponent
        end
      RUBY
    end
  end

  context "when the parent resolves to a non-ViewComponent class" do
    it "does not register an offense even when the name ends with Component" do
      expect_no_offenses(<<~RUBY)
        class WidgetComponent
        end

        class UserCardComponent < WidgetComponent
        end
      RUBY
    end
  end

  context "when inheriting from a namespaced abstract base class" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        module Shadcn
          class ApplicationViewComponent < ViewComponent::Base
          end

          module Button
            class Component < ApplicationViewComponent
            end
          end
        end
      RUBY
    end
  end

  context "when class has no parent" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class UserCard
        end
      RUBY
    end
  end

  context "when ComponentNamespaces is configured" do
    let(:config) do
      RuboCop::Config.new(
        "ViewComponent/PreferComposition" => {
          "ComponentNamespaces" => ["V2::"]
        }
      )
    end

    it "registers an offense for a class in a configured namespace" do
      expect_offense(<<~RUBY)
        class UserCard < V2::Table
                         ^^^^^^^^^ Avoid inheriting from another ViewComponent.
        end
      RUBY
    end

    it "does not register an offense for a class outside configured namespaces" do
      expect_no_offenses(<<~RUBY)
        class UserCard < SomeOtherBase
        end
      RUBY
    end
  end
end
