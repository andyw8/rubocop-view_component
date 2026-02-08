# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::PreferComposition, :config do
  let(:config) { RuboCop::Config.new }

  context "when inheriting from another component" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        class UserCard < BaseCardComponent
                         ^^^^^^^^^^^^^^^^^ ViewComponent/PreferComposition: Avoid inheriting from another ViewComponent. Instead, render the parent component in your template: `<%= render ParentComponent.new %>`
        end
      RUBY
    end

    it "registers an offense for namespaced component parent" do
      expect_offense(<<~RUBY)
        class UserCard < Admin::BaseComponent
                         ^^^^^^^^^^^^^^^^^^^^ ViewComponent/PreferComposition: Avoid inheriting from another ViewComponent. Instead, render the parent component in your template: `<%= render ParentComponent.new %>`
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

  context "when class has no parent" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class UserCard
        end
      RUBY
    end
  end

  context "when ViewComponentParentClasses is configured" do
    let(:config) do
      RuboCop::Config.new(
        "AllCops" => {
          "ViewComponentParentClasses" => ["Primer::Component"]
        }
      )
    end

    it "does not register an offense for configured parent classes" do
      expect_no_offenses(<<~RUBY)
        class FooBarComponent < Primer::Component
        end
      RUBY
    end
  end
end
