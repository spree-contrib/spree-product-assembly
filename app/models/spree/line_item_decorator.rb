Spree::LineItem.class_eval do

  validate :validate_quantity_and_stock
  has_many :assembly_variants

  def sufficient_stock?
    return true if Spree::Config[:allow_backorders]
    if product.assembly?
      !assembly_variants.map(&:variant).select{|part| part.on_hand < product.count_of(part.product)}.any?
    else
      if new_record? || !order.completed?
        variant.on_hand >= quantity
      else
        variant.on_hand >= (quantity - self.changed_attributes['quantity'].to_i)
      end
    end
  end

  private
    def validate_quantity_and_stock
      unless quantity && quantity >= 0
        errors.add(:quantity, I18n.t("validation.must_be_non_negative"))
      end
      # avoid reload of order.inventory_units by using direct lookup
      unless !Spree::Config[:track_inventory_levels]                        ||
             Spree::Config[:allow_backorders]                               ||
             order   && Spree::InventoryUnit.where(:order_id => order.id).first.present? ||
             variant && quantity <= variant.on_hand
        errors.add(:quantity, I18n.t("validation.is_too_large") + " (#{self.variant.name})")
      end

      return unless variant
    end

    # Overriden from Spree core to properly manage inventory units when item
    # is a product bundle
    def update_inventory
      return true unless order.completed?

      if new_record?
        increase_inventory_with_assembly(quantity)
      elsif old_quantity = self.changed_attributes['quantity']
        if old_quantity < quantity
          increase_inventory_with_assembly(quantity - old_quantity)
        elsif old_quantity > quantity
          decrease_inventory_with_assembly(old_quantity - quantity)
        end
      end
    end

    def increase_inventory_with_assembly(number)
      if product.assembly?
        product.parts.each{ |part| Spree::InventoryUnit.increase(order, part, number * product.count_of(part)) }
      else
        Spree::InventoryUnit.increase(order, variant, number)
      end
    end

    def decrease_inventory_with_assembly(number)
      if product.assembly?
        product.parts.each{ |part| Spree::InventoryUnit.decrease(order, part, number * product.count_of(part)) }
      else
        Spree::InventoryUnit.increase(order, variant, number)
      end
    end
end
