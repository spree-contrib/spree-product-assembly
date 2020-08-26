module Spree::VariantDecorator
  def self.prepended(base)
    base.has_many :parts_variants, class_name: "Spree::AssembliesPart", foreign_key: "assembly_id"
    base.has_many :assemblies_variants, class_name: "Spree::AssembliesPart", foreign_key: "part_id"

    base.has_many :assemblies, through: :assemblies_variants, class_name: "Spree::Variant", dependent: :destroy
    base.has_many :parts, through: :parts_variants, class_name: "Spree::Variant", dependent: :destroy
  end

  before_destroy :ensure_no_inventory_units

  def assemblies_for(products)
    assemblies.where(id: products)
  end

  def part?
    assemblies.exists?
  end

  private
    def ensure_no_inventory_units
      if inventory_units.any?
        errors.add(:base, Spree.t(:cannot_destroy_if_attached_to_inventory_units))
        return false
      end
    end
end

Spree::Variant.prepend Spree::VariantDecorator
