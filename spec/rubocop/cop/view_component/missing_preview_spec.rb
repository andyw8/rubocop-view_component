# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::MissingPreview, :config do
  let(:config) do
    RuboCop::Config.new(
      "ViewComponent/MissingPreview" => {
        "Enabled" => true,
        "PreviewPaths" => ["/previews"]
      }
    )
  end

  context "when a preview file exists" do
    it "does not register an offense" do
      allow(File).to receive(:exist?).and_return(true)

      expect_no_offenses(<<~RUBY, "/app/components/user_component.rb")
        class UserComponent < ViewComponent::Base
        end
      RUBY
    end
  end

  context "when no preview file exists" do
    it "registers an offense" do
      allow(File).to receive(:exist?).and_return(false)

      expect_offense(<<~RUBY, "/app/components/user_component.rb")
        class UserComponent < ViewComponent::Base
              ^^^^^^^^^^^^^ No preview found for UserComponent (looked in: /previews).
        end
      RUBY
    end
  end

  context "when not a ViewComponent" do
    it "does not register an offense" do
      allow(File).to receive(:exist?).and_return(false)

      expect_no_offenses(<<~RUBY, "/app/components/user_component.rb")
        class UserComponent
        end
      RUBY
    end
  end
end
