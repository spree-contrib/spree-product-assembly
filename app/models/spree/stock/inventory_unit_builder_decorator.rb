module Spree
  module Stock
    InventoryUnitBuilder.class_eval do
      def units
        @order.line_items.flat_map do |line_item|
          line_item.quantity_by_variant.flat_map do |variant, quantity|
            build_inventory_unit(variant, line_item, quantity)
          end
        end
      end

      def build_inventory_unit(variant, line_item)
        @order.inventory_units.includes(
          variant: {
            product: {
              shipping_category: {
                shipping_methods: [:calculator, { zones: :zone_members }]
              }
            }
          }
        ).build(
          pending: true,
          variant: variant,
          line_item: line_item,
          order: @order, 
          quantity: quantity
        )
      end
    end
  end
end
