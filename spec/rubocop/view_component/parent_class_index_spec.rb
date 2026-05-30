# frozen_string_literal: true

RSpec.describe RuboCop::ViewComponent::ParentClassIndex do
  let(:cop_config) { {} }

  before do
    described_class.reset!
    allow(Dir).to receive(:glob).with("app/components/**/*.rb").and_return([])
  end

  after { described_class.reset! }

  def stub_component(path, source)
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f, path)
    allow(RuboCop::ProcessedSource).to receive(:from_file).with(path, RUBY_VERSION.to_f).and_return(processed)
  end

  describe "#known_parent?" do
    it "recognises ViewComponent::Base" do
      expect(described_class.known_parent?("ViewComponent::Base", cop_config)).to be true
    end

    it "recognises ApplicationComponent" do
      expect(described_class.known_parent?("ApplicationComponent", cop_config)).to be true
    end

    it "does not recognise an unknown class" do
      expect(described_class.known_parent?("SomeRandom::Class", cop_config)).to be false
    end

    context "when ViewComponentParentClasses is configured" do
      let(:cop_config) { { "ViewComponentParentClasses" => ["MyApp::BaseComponent"] } }

      it "recognises the configured class" do
        expect(described_class.known_parent?("MyApp::BaseComponent", cop_config)).to be true
      end
    end

    context "when a class inherits directly from ViewComponent::Base" do
      before do
        allow(Dir).to receive(:glob).with("app/components/**/*.rb")
                                    .and_return(["app/components/base_component.rb"])
        stub_component("app/components/base_component.rb", "class BaseComponent < ViewComponent::Base; end")
      end

      it "recognises the direct descendant as a known parent" do
        expect(described_class.known_parent?("BaseComponent", cop_config)).to be true
      end
    end

    context "when a class inherits transitively from ViewComponent::Base" do
      before do
        allow(Dir).to receive(:glob).with("app/components/**/*.rb")
                                    .and_return(["app/components/base_component.rb",
                                                 "app/components/abstract_component.rb"])
        stub_component("app/components/base_component.rb", "class BaseComponent < ViewComponent::Base; end")
        stub_component("app/components/abstract_component.rb", "class AbstractComponent < BaseComponent; end")
      end

      it "recognises the transitive descendant as a known parent" do
        expect(described_class.known_parent?("AbstractComponent", cop_config)).to be true
      end
    end

    context "when inheritance chain is three levels deep" do
      before do
        allow(Dir).to receive(:glob).with("app/components/**/*.rb").and_return([
                                                                                 "app/components/base_component.rb",
                                                                                 "app/components/mid_component.rb",
                                                                                 "app/components/leaf_component.rb"
                                                                               ])
        stub_component("app/components/base_component.rb", "class BaseComponent < ViewComponent::Base; end")
        stub_component("app/components/mid_component.rb", "class MidComponent < BaseComponent; end")
        stub_component("app/components/leaf_component.rb", "class LeafComponent < MidComponent; end")
      end

      it "recognises BaseComponent as a known parent" do
        expect(described_class.known_parent?("BaseComponent", cop_config)).to be true
      end

      it "recognises MidComponent as a known parent" do
        expect(described_class.known_parent?("MidComponent", cop_config)).to be true
      end

      it "recognises LeafComponent as a known parent" do
        expect(described_class.known_parent?("LeafComponent", cop_config)).to be true
      end
    end

    context "when a class does not inherit from a ViewComponent root" do
      before do
        allow(Dir).to receive(:glob).with("app/components/**/*.rb")
                                    .and_return(["app/components/helper.rb"])
        stub_component("app/components/helper.rb", "class Helper < SomeOtherBase; end")
      end

      it "does not recognise the unrelated class" do
        expect(described_class.known_parent?("Helper", cop_config)).to be false
      end
    end

    context "when a namespaced class inherits from ViewComponent::Base" do
      before do
        allow(Dir).to receive(:glob).with("app/components/**/*.rb")
                                    .and_return(["app/components/admin/base_component.rb"])
        stub_component(
          "app/components/admin/base_component.rb",
          "module Admin\n  class BaseComponent < ViewComponent::Base; end\nend"
        )
      end

      it "recognises the namespaced class as a known parent" do
        expect(described_class.known_parent?("Admin::BaseComponent", cop_config)).to be true
      end
    end

    context "with memoization" do
      it "only scans once across multiple calls" do
        described_class.known_parent?("ViewComponent::Base", cop_config)
        described_class.known_parent?("ApplicationComponent", cop_config)
        expect(Dir).to have_received(:glob).once
      end

      it "rescans after reset!" do
        described_class.known_parent?("ViewComponent::Base", cop_config)
        described_class.reset!
        allow(Dir).to receive(:glob).with("app/components/**/*.rb").and_return([])
        described_class.known_parent?("ViewComponent::Base", cop_config)
        expect(Dir).to have_received(:glob).twice
      end
    end
  end
end
