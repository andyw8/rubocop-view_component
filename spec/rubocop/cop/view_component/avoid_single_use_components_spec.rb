# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::AvoidSingleUseComponents, :config do
  let(:config) { RuboCop::Config.new }

  context "when component has only initialize" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        class SimpleWrapperComponent < ViewComponent::Base
              ^^^^^^^^^^^^^^^^^^^^^^ ViewComponent/AvoidSingleUseComponents: This component appears to be trivial. Consider whether a partial would be simpler.
          def initialize(content)
            @content = content
          end
        end
      RUBY
    end
  end

  context "when component has an empty body" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        class EmptyComponent < ViewComponent::Base
              ^^^^^^^^^^^^^^ ViewComponent/AvoidSingleUseComponents: This component appears to be trivial. Consider whether a partial would be simpler.
        end
      RUBY
    end
  end

  context "when component has additional methods" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def initialize(title)
            @title = title
          end

          def formatted_title
            @title.upcase
          end
        end
      RUBY
    end

    it "does not register an offense for private methods" do
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

  context "when component has slots" do
    it "does not register an offense with renders_one" do
      expect_no_offenses(<<~RUBY)
        class ModalComponent < ViewComponent::Base
          renders_one :header

          def initialize(title:)
            @title = title
          end
        end
      RUBY
    end

    it "does not register an offense with renders_many" do
      expect_no_offenses(<<~RUBY)
        class ListComponent < ViewComponent::Base
          renders_many :items

          def initialize(title:)
            @title = title
          end
        end
      RUBY
    end
  end

  context "when not a ViewComponent" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class SimpleClass < ActiveRecord::Base
          def initialize(name)
            @name = name
          end
        end
      RUBY
    end
  end
end
