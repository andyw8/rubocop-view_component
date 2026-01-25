# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::PreferSlots, :config do
  let(:config) { RuboCop::Config.new }

  context 'when initialize has HTML parameter names' do
    it 'registers offense for _html suffix' do
      expect_offense(<<~RUBY)
        class ModalComponent < ViewComponent::Base
          def initialize(title:, body_html:)
                                 ^^^^^^^^^^ ViewComponent/PreferSlots: Consider using `renders_one :body` instead of passing HTML as a parameter. This maintains Rails' automatic HTML escaping.
            @title = title
            @body_html = body_html
          end
        end
      RUBY
    end

    it 'registers offense for _content suffix' do
      expect_offense(<<~RUBY)
        class ModalComponent < ViewComponent::Base
          def initialize(title:, body_content:)
                                 ^^^^^^^^^^^^^ ViewComponent/PreferSlots: Consider using `renders_one :body` instead of passing HTML as a parameter. This maintains Rails' automatic HTML escaping.
            @title = title
            @body_content = body_content
          end
        end
      RUBY
    end

    it 'registers offense for html_ prefix' do
      expect_offense(<<~RUBY)
        class ModalComponent < ViewComponent::Base
          def initialize(title:, html_body:)
                                 ^^^^^^^^^^ ViewComponent/PreferSlots: Consider using `renders_one :body` instead of passing HTML as a parameter. This maintains Rails' automatic HTML escaping.
            @title = title
            @html_body = html_body
          end
        end
      RUBY
    end

    it 'registers offense for content parameter' do
      expect_offense(<<~RUBY)
        class ModalComponent < ViewComponent::Base
          def initialize(title:, content:)
                                 ^^^^^^^^ ViewComponent/PreferSlots: Consider using `renders_one :content` instead of passing HTML as a parameter. This maintains Rails' automatic HTML escaping.
            @title = title
            @content = content
          end
        end
      RUBY
    end
  end

  context 'when parameter has html_safe default value' do
    it 'registers offense' do
      expect_offense(<<~RUBY)
        class ModalComponent < ViewComponent::Base
          def initialize(title:, body: "".html_safe)
                                 ^^^^^^^^^^^^^^^^^^ ViewComponent/PreferSlots: Consider using `renders_one :body` instead of passing HTML as a parameter. This maintains Rails' automatic HTML escaping.
            @title = title
            @body = body
          end
        end
      RUBY
    end
  end

  context 'when parameters are not HTML-related' do
    it 'does not register offense for regular parameters' do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def initialize(title:, description:)
            @title = title
            @description = description
          end
        end
      RUBY
    end

    it 'does not register offense for html_class' do
      expect_no_offenses(<<~RUBY)
        class CardComponent < ViewComponent::Base
          def initialize(title:, html_class:)
            @title = title
            @html_class = html_class
          end
        end
      RUBY
    end
  end

  context 'when not a ViewComponent' do
    it 'does not register offense' do
      expect_no_offenses(<<~RUBY)
        class RegularClass
          def initialize(body_html:)
            @body_html = body_html
          end
        end
      RUBY
    end
  end

  context 'when component uses slots' do
    it 'does not register offense' do
      expect_no_offenses(<<~RUBY)
        class ModalComponent < ViewComponent::Base
          renders_one :body

          def initialize(title:)
            @title = title
          end
        end
      RUBY
    end
  end
end
