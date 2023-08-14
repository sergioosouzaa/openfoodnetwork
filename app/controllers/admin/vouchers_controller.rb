# frozen_string_literal: true

module Admin
  class VouchersController < ResourceController
    before_action :load_enterprise

    def new
      @voucher = Voucher.new
    end

    def create
      # In the scenario where you get an error when trying to create a percentage voucher, we'll
      # now have percentage rate voucher instanciated. Hence why we check for both params type
      voucher_type = params.dig(:voucher, :voucher_type)

      # The use of "safe_constantize" here will trigger a Brakeman error, it can safely be ignored
      # as it's a false positive : https://github.com/openfoodfoundation/openfoodnetwork/pull/10821
      if Voucher::TYPES.include?(voucher_type)
        @voucher = voucher_type.safe_constantize.create(
          permitted_resource_params.merge(enterprise: @enterprise)
        )
      else
        @voucher.errors.add(:type)
        return render_error
      end

      if @voucher.save
        flash[:success] = I18n.t(:successfully_created, resource: "Voucher")
        redirect_to edit_admin_enterprise_path(@enterprise, anchor: :vouchers_panel)
      else
        render_error
      end
    end

    private

    def render_error
      flash[:error] = @voucher.errors.full_messages.to_sentence
      render :new
    end

    def load_enterprise
      @enterprise = OpenFoodNetwork::Permissions
        .new(spree_current_user)
        .editable_enterprises
        .find_by(permalink: params[:enterprise_id])
    end

    def permitted_resource_params
      params.require(:voucher).permit(:code, :amount)
    end
  end
end
