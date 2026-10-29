# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe RuboCop::Cop::ViewComponent::TemplateAnalyzer do
  subject(:analyzer) { Object.new.extend(described_class) }

  let(:directory) { Dir.mktmpdir("template_analyzer") }

  after { FileUtils.remove_entry(directory) }

  describe "#template_paths_for" do
    let(:component_path) { File.join(directory, "example_component.rb") }

    before do
      File.write(component_path, "")
      %w[
        example_component.erb
        example_component.html.erb
        example_component.en.html.haml
        example_component.html.slim
      ].each do |name|
        File.write(File.join(directory, name), "")
      end

      sidecar_directory = File.join(directory, "example_component")
      FileUtils.mkdir_p(sidecar_directory)
      File.write(File.join(sidecar_directory, "example_component.html.haml"), "")
      File.write(File.join(sidecar_directory, "unrelated.rb"), "")
    end

    it "finds sibling and sidecar templates in every supported language" do
      expect(analyzer.template_paths_for(component_path)).to contain_exactly(
        File.join(directory, "example_component.erb"),
        File.join(directory, "example_component.html.erb"),
        File.join(directory, "example_component.en.html.haml"),
        File.join(directory, "example_component.html.slim"),
        File.join(directory, "example_component", "example_component.html.haml")
      )
    end
  end

  describe "#extract_method_calls" do
    it "extracts method calls from ERB" do
      path = write_template("example.html.erb", "<h1><%= formatted_title %></h1>\n")

      expect(analyzer.extract_method_calls(path)).to eq(Set[:formatted_title])
    end

    it "extracts method calls from Haml" do
      path = write_template("example.html.haml", "%h1{title: tooltip_text}= formatted_title\n")

      expect(analyzer.extract_method_calls(path)).to eq(Set[:tooltip_text, :formatted_title])
    end

    it "extracts method calls from Slim" do
      path = write_template("example.html.slim", "h1 title=tooltip_text = formatted_title\n")

      expect(analyzer.extract_method_calls(path)).to eq(Set[:tooltip_text, :formatted_title])
    end

    it "extracts method calls from Haml control flow and blocks" do
      path = write_template("example.html.haml", <<~HAML)
        .card
          - if show_icon?
            = render IconComponent.new(name: icon_name) { helper_block }
      HAML

      expect(analyzer.extract_method_calls(path)).to include(
        :show_icon?,
        :icon_name,
        :helper_block
      )
    end

    it "returns an empty set for an unsupported template language" do
      path = write_template("example.txt", "formatted_title\n")

      expect(analyzer.extract_method_calls(path)).to eq(Set.new)
    end

    it "returns an empty set when the template does not exist" do
      expect(analyzer.extract_method_calls(File.join(directory, "missing.html.haml"))).to eq(Set.new)
    end
  end

  def write_template(name, content)
    path = File.join(directory, name)
    File.write(path, content)
    path
  end
end
