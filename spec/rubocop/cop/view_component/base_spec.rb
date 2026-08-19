# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::Base do
  let(:cop_class) { RuboCop::Cop::ViewComponent::ComponentSuffix }
  let(:cop) { cop_class.new(RuboCop::Config.new) }

  before do
    cop.project_index = nil
  end

  describe "#view_component_class?" do
    it "raises when project_index is not set and class is not in ComponentNamespaces" do
      source = parse_source(<<~RUBY)
        class Foo < ViewComponent::Base
        end
      RUBY

      expect { cop.send(:view_component_class?, source.ast) }.to raise_error(
        RuntimeError,
        /UseProjectIndex/
      )
    end

    it "does not raise when class matches a ComponentNamespace" do
      config = RuboCop::Config.new(
        "ViewComponent/ComponentSuffix" => {
          "ComponentNamespaces" => ["MyApp::"]
        }
      )
      cop = cop_class.new(config)
      cop.project_index = nil

      source = parse_source(<<~RUBY)
        module MyApp
          class Foo < ViewComponent::Base
          end
        end
      RUBY

      class_node = source.ast.body

      expect(cop.send(:view_component_class?, class_node)).to be true
    end
  end

  describe "#view_component_parent?" do
    it "raises when project_index is not set" do
      source = parse_source(<<~RUBY)
        class Foo < ViewComponent::Base
        end
      RUBY

      parent = source.ast.parent_class

      expect { cop.send(:view_component_parent?, parent) }.to raise_error(
        RuntimeError,
        /UseProjectIndex/
      )
    end
  end

  describe "#view_component_parent_class?" do
    it "raises when project_index is not set" do
      source = parse_source(<<~RUBY)
        class Foo < ViewComponent::Base
        end
      RUBY

      expect { cop.send(:view_component_parent_class?, source.ast) }.to raise_error(
        RuntimeError,
        /UseProjectIndex/
      )
    end
  end

  describe "#inside_view_component?" do
    it "raises when project_index is not set" do
      source = parse_source(<<~RUBY)
        class Foo < ViewComponent::Base
          def call; end
        end
      RUBY

      method_node = source.ast.body

      expect { cop.send(:inside_view_component?, method_node) }.to raise_error(
        RuntimeError,
        /UseProjectIndex/
      )
    end
  end
end
