# frozen_string_literal: true

module RuboCop
  module Cop
    module ViewComponent
      # Ensures that every ViewComponent has a corresponding preview file.
      #
      # Looks for previews in the configured PreviewPaths, supporting both
      # naming conventions: `user_preview.rb` and `user_component_preview.rb`.
      #
      class MissingPreview < RuboCop::Cop::Base
        include ViewComponent::Base

        MSG = "No preview found for %<component>s (looked in: %<paths>s)."

        def on_class(node)
          return unless view_component_class?(node)

          class_name = node.identifier.source
          return if preview_exists?(class_name)

          add_offense(node.identifier, message: format(MSG, component: class_name, paths: preview_paths.join(", ")))
        end

        private

        def preview_exists?(class_name)
          preview_paths.any? do |preview_path|
            candidate_filenames(class_name).any? do |filename|
              File.exist?(File.join(preview_path, filename))
            end
          end
        end

        def candidate_filenames(class_name)
          base = class_name.gsub(/Component$/, "").gsub(/([A-Z])/, '_\1').downcase.delete_prefix("_")
          [
            "#{base}_preview.rb",
            "#{base}_component_preview.rb"
          ]
        end

        def preview_paths
          cop_config.fetch("PreviewPaths", [])
        end
      end
    end
  end
end
