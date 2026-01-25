# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::ComponentSuffix, :config do
  let(:config) { RuboCop::Config.new }

  context "when class inherits from ViewComponent::Base" do
    it "registers an offense when class name does not end with Component" do
      expect_offense(<<~RUBY)
        class FooBar < ViewComponent::Base
              ^^^^^^ ViewComponent/ComponentSuffix: ViewComponent class names should end with `Component`.
        end
      RUBY
    end

    it "does not register offense when class name ends with Component" do
      expect_no_offenses(<<~RUBY)
        class FooBarComponent < ViewComponent::Base
        end
      RUBY
    end
  end

  context "when class inherits from ApplicationComponent" do
    it "registers an offense when class name does not end with Component" do
      expect_offense(<<~RUBY)
        class UserCard < ApplicationComponent
              ^^^^^^^^ ViewComponent/ComponentSuffix: ViewComponent class names should end with `Component`.
        end
      RUBY
    end

    it "does not register offense when class name ends with Component" do
      expect_no_offenses(<<~RUBY)
        class UserCardComponent < ApplicationComponent
        end
      RUBY
    end
  end

  context "when class does not inherit from ViewComponent" do
    it "does not register offense for regular classes" do
      expect_no_offenses(<<~RUBY)
        class FooBar < SomeOtherBase
        end
      RUBY
    end

    it "does not register offense for plain classes" do
      expect_no_offenses(<<~RUBY)
        class FooBar
        end
      RUBY
    end
  end

  context "with namespaced components" do
    it "checks the final component name" do
      expect_offense(<<~RUBY)
        module Admin
          class UserCard < ViewComponent::Base
                ^^^^^^^^ ViewComponent/ComponentSuffix: ViewComponent class names should end with `Component`.
          end
        end
      RUBY
    end

    it "allows namespaced component with Component suffix" do
      expect_no_offenses(<<~RUBY)
        module Admin
          class UserCardComponent < ViewComponent::Base
          end
        end
      RUBY
    end
  end

  context "with compact nested class syntax" do
    it "registers offense for compact syntax" do
      expect_offense(<<~RUBY)
        class Admin::UserCard < ViewComponent::Base
              ^^^^^^^^^^^^^^^ ViewComponent/ComponentSuffix: ViewComponent class names should end with `Component`.
        end
      RUBY
    end
  end
end
