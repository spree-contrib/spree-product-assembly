Spree::Product.class_eval do
  
  has_and_belongs_to_many  :assemblies, :class_name => "Spree::Product",
        :join_table => "spree_assemblies_parts",
        :foreign_key => "part_id", :association_foreign_key => "assembly_id"

  has_and_belongs_to_many  :parts, :class_name => "Spree::Variant",
        :join_table => "spree_assemblies_parts",
        :foreign_key => "assembly_id", :association_foreign_key => "part_id"


  scope :individual_saled, where(["spree_products.individual_sale = ?", true])

  scope :active, lambda { |*args|
    not_deleted.individual_saled.available(nil, args.first)
  }

  attr_accessible :can_be_part, :individual_sale

  # returns the number of inventory units "on_hand" for this product
  def on_hand_with_assembly(reload = false)
    if self.assembly? && Spree::Config[:track_inventory_levels]
      parts(reload).map{|v| v.on_hand / self.count_of(v) }.min
    else
      on_hand_without_assembly
    end
  end
  alias_method_chain :on_hand, :assembly

  alias_method :orig_on_hand=, :on_hand=
  def on_hand=(new_level)
    self.orig_on_hand=(new_level) unless self.assembly?
  end

  alias_method :orig_has_stock?, :has_stock?
  def has_stock?
    if self.assembly? && Spree::Config[:track_inventory_levels]
      !parts.detect{|v| self.count_of(v) > v.on_hand}
    else
      self.orig_has_stock?
    end
  end

  def add_part(variant, count = 1)
    ap = Spree::AssembliesPart.get(self.id, variant.id)
    if ap
      ap.count += count
      ap.save
    else
      self.parts << variant
      set_part_count(variant, count) if count > 1
    end
  end

  def remove_part(variant)
    ap = Spree::AssembliesPart.get(self.id, variant.id)
    unless ap.nil?
      ap.count -= 1
      if ap.count > 0
        ap.save
      else
        ap.destroy
      end
    end
  end

  def set_part_count(variant, count)
    ap = Spree::AssembliesPart.get(self.id, variant.id)
    unless ap.nil?
      if count > 0
        ap.count = count
        ap.save
      else
        ap.destroy
      end
    end
  end

  def assembly?
    parts.present?
  end

  def part?
    assemblies.present?
  end

  def count_of(variant)
    ap = Spree::AssembliesPart.get(self.id, variant.id)
    ap ? ap.count : 0
  end

end
