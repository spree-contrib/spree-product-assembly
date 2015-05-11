Spree::Variant.class_eval do
  has_and_belongs_to_many  :assemblies, :class_name => "Spree::Product",
        :join_table => "spree_assemblies_parts",
        :foreign_key => "part_id", :association_foreign_key => "assembly_id"

  def assemblies_for(products)
    assemblies.where(id: products)
  end

  def part?
    assemblies.exists?
  end

  def backorderable
    is_backorderable?
  end

  def backorderable=(value)
    self.stock_items.each do |stock_item|
      stock_item.backorderable = value
      stock_item.save
    end
  end

  def sku_and_options_text(show_product_name=false)
    if !show_product_name
      "#{sku} #{options_text}".strip
    else
      "#{name}: #{options_text}".strip
    end
  end

  # Shortcut method to determine if inventory tracking enabled for this variant
  # Considers both variant tracking flag & site-wide inventory tracking settings
  # Add checking for assembly with master variant that doesn't track inventory
  def should_track_inventory?
    Spree::Config.track_inventory_levels &&
      (self.track_inventory? || self.product.assembly? && self.is_master?)
  end
end
