# frozen_string_literal: true

class TemplateMethodComponent < ViewComponent::Base
  def initialize(title)
    @title = title
  end

  def formatted_title
    @title.upcase
  end

  def helper_not_used
    "not used"
  end
end
