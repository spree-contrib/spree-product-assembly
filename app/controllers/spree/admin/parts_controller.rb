class Spree::Admin::PartsController < Spree::Admin::BaseController
  before_filter :find_product

  def index
    @parts = @variant.parts
  end

  def remove
    @part = Spree::Variant.find(params[:id])
    @variant.remove_part(@part)
    render 'spree/admin/parts/update_parts_table'
  end

  def set_count
    @part = Spree::Variant.find(params[:id])
    @variant.set_part_count(@part, params[:count].to_i)
    render 'spree/admin/parts/update_parts_table'
  end

  def available
    if params[:q].blank?
      @available_products = []
    else
      query = "%#{params[:q]}%"
      @available_products = Spree::Product.search_can_be_part(query)
      @available_products.uniq!
    end
    respond_to do |format|
      format.html {render :layout => false}
      format.js {render :layout => false}
    end
  end

  def create
    @part = Spree::Variant.find(params[:part_id])
    qty = params[:part_count].to_i
    @variant.add_part(@part, qty) if qty > 0
    render 'spree/admin/parts/update_parts_table'
  end

  private
    def find_product
      if params[:variant_id]
        @variant = Spree::Variant.find(params[:variant_id])
        @product = @variant.product
      else
        @product = Spree::Product.find_by(slug: params[:product_id])
        @variant = @product.master
      end
    end
end
