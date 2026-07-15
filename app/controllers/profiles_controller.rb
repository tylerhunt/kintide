require 'dry/monads'

class ProfilesController < ApplicationController
  include Dry::Monads[:result]

  schema :edit

  def edit; end

  schema :update do
    required(:name).filled(:string)
    optional(:avatar)
  end

  def update
    case resolve('accounts.update_profile').call(
      account: Current.account,
      **safe_params.to_h,
    )
    in Success(*)
      redirect_to root_path, notice: t('flash.profiles.updated')
    in Failure[:invalid, errors]
      render :edit, status: :unprocessable_content, locals: { errors: }
    in Failure[:update_account, account]
      render :edit, status: :unprocessable_content,
        locals: { errors: account.errors.to_hash }
    end
  end
end
