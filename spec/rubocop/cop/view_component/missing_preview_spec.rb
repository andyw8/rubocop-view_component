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

  context "when ComponentNamespaces is configured" do
    let(:config) do
      RuboCop::Config.new(
        "ViewComponent/MissingPreview" => {
          "Enabled" => true,
          "PreviewPaths" => ["/previews"],
          "ComponentNamespaces" => ["V2::"]
        }
      )
    end

    it "registers an offense for a component in a configured namespace" do
      allow(File).to receive(:exist?).and_return(false)

      expect_offense(<<~RUBY, "/app/components/v2/table.rb")
        class V2::Table < SomeBase
              ^^^^^^^^^ No preview found for V2::Table (looked in: /previews).
        end
      RUBY
    end

    it "checks the correct preview path for namespaced classes" do
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with("/previews/v2/grouped_multi_select_preview.rb").and_return(true)

      expect_no_offenses(<<~RUBY, "/app/components/v2/grouped_multi_select.rb")
        class V2::GroupedMultiSelect < V2::MultiSelect
        end
      RUBY
    end

    it "checks the correct preview path for deeply namespaced classes" do
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with("/previews/v2/catalogs/index_table_preview.rb").and_return(true)

      expect_no_offenses(<<~RUBY, "/app/components/v2/catalogs/index_table.rb")
        class V2::Catalogs::IndexTable < V2::Table
        end
      RUBY
    end

    it "does not register an offense for a non-component class in a configured namespace" do
      allow(File).to receive(:exist?).and_return(false)

      expect_no_offenses(<<~RUBY, "/app/models/user.rb")
        class User < SomeBase
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
