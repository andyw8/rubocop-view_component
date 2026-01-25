# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ViewComponent::NoGlobalState, :config do
  let(:config) { RuboCop::Config.new }

  context 'when accessing params' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class UserComponent < ViewComponent::Base
          def admin?
            params[:admin]
            ^^^^^^ ViewComponent/NoGlobalState: Avoid accessing `params` directly in ViewComponents. Pass necessary data through the constructor instead.
          end
        end
      RUBY
    end

    it 'registers offense for params method call' do
      expect_offense(<<~RUBY)
        class UserComponent < ViewComponent::Base
          def admin?
            params.fetch(:admin)
            ^^^^^^ ViewComponent/NoGlobalState: Avoid accessing `params` directly in ViewComponents. Pass necessary data through the constructor instead.
          end
        end
      RUBY
    end
  end

  context 'when accessing request' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class UserComponent < ViewComponent::Base
          def user_agent
            request.user_agent
            ^^^^^^^ ViewComponent/NoGlobalState: Avoid accessing `request` directly in ViewComponents. Pass necessary data through the constructor instead.
          end
        end
      RUBY
    end
  end

  context 'when accessing session' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class UserComponent < ViewComponent::Base
          def current_user_id
            session[:user_id]
            ^^^^^^^ ViewComponent/NoGlobalState: Avoid accessing `session` directly in ViewComponents. Pass necessary data through the constructor instead.
          end
        end
      RUBY
    end
  end

  context 'when accessing cookies' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class UserComponent < ViewComponent::Base
          def preference
            cookies[:theme]
            ^^^^^^^ ViewComponent/NoGlobalState: Avoid accessing `cookies` directly in ViewComponents. Pass necessary data through the constructor instead.
          end
        end
      RUBY
    end
  end

  context 'when accessing flash' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class UserComponent < ViewComponent::Base
          def notice
            flash[:notice]
            ^^^^^ ViewComponent/NoGlobalState: Avoid accessing `flash` directly in ViewComponents. Pass necessary data through the constructor instead.
          end
        end
      RUBY
    end
  end

  context 'when not accessing global state' do
    it 'does not register offense for instance variables' do
      expect_no_offenses(<<~RUBY)
        class UserComponent < ViewComponent::Base
          def initialize(admin:)
            @admin = admin
          end

          def admin?
            @admin
          end
        end
      RUBY
    end

    it 'does not register offense for method arguments' do
      expect_no_offenses(<<~RUBY)
        class UserComponent < ViewComponent::Base
          def format_params(params)
            params[:admin]
          end
        end
      RUBY
    end
  end

  context 'when not in a ViewComponent' do
    it 'does not register offense in regular classes' do
      expect_no_offenses(<<~RUBY)
        class RegularClass
          def admin?
            params[:admin]
          end
        end
      RUBY
    end
  end
end
