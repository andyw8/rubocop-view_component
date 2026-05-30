# frozen_string_literal: true

require "active_support/inflector"

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
          return if view_component_parent_class?(node)
          return if allow_slot_subcomponents? && slot_subcomponent?(node)

          class_name = fully_qualified_name(node)
          return if preview_exists?(class_name)

          add_offense(node.identifier, message: format(MSG, component: class_name, paths: preview_paths.join(", ")))
        end

        private

        def allow_slot_subcomponents?
          cop_config.fetch("AllowSlotSubcomponents", false)
        end

        def slot_subcomponent?(node)
          nested_in_view_component?(node) || under_parent_component_dir?(node)
        end

        def nested_in_view_component?(node)
          parent = node.each_ancestor(:class).first
          parent && view_component_class?(parent)
        end

        def under_parent_component_dir?(node)
          path = processed_source.path
          return false unless path

          dir = File.dirname(path)
          parent_file = ["#{dir}.rb", "#{dir}_component.rb"].find { |f| File.exist?(f) }
          return false unless parent_file

          short_name = node.identifier.source
          parent_source = cached_file_read(parent_file)
          # Match class name on the same line as renders_one/many OR within a
          # short lambda block on the following lines (covers .new(...) inside
          # ->(...) do ... end). We allow up to ~5 lines after renders_ to avoid
          # false positives from unrelated later occurrences of the class name.
          parent_source.match?(/renders_(one|many)\b[^\n]*(?:\n[^\n]*){0,5}\b#{Regexp.escape(short_name)}\b/)
        end

        def cached_file_read(path)
          @file_cache ||= {}
          @file_cache[path] ||= File.read(path)
        end

        def preview_exists?(class_name)
          preview_paths.any? do |preview_path|
            candidate_filenames(class_name).any? do |filename|
              File.exist?(File.join(preview_path, filename))
            end
          end
        end

        def candidate_filenames(class_name)
          bases = [ActiveSupport::Inflector.underscore(class_name.delete_suffix("Component"))]
          short_name = class_name.split("::").last
          short_base = ActiveSupport::Inflector.underscore(short_name.delete_suffix("Component"))
          bases << short_base if short_base != bases.first
          bases.flat_map { |base| ["#{base}_preview.rb", "#{base}_component_preview.rb"] }
        end

        def preview_paths
          cop_config.fetch("PreviewPaths", [])
        end
      end
    end
  end
end
