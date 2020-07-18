module Spree
  class AssignPartToBundleForm
    include ActiveModel::Validations

    validates :quantity, numericality: {greater_than: 0}
    validates :part_id, numericality: { other_than: :assembly_id, message: Spree.t(:must_be_other_than_assembly) }

    attr_reader :product, :part_options

    def initialize(product, part_options)
      @product = product
      @part_options = part_options
    end

    def submit
      if valid?
        assemblies_part.update(attributes)
      end
    end

    private

    def attributes
      part_options.reject {|k, v| k.to_sym == :part_id}
    end

    def given_id?
      part_options[:id].present?
    end

    def assembly_id
      assembly.id
    end

    def part_id
      part.id
    end

    def assembly
      Spree::Variant.find_by(id: part_options[:assembly_id])
    end

    def part
      if part_options[:part_id]
        Spree::Variant.find_by(id: part_options[:part_id])
      else
        product.master
      end
    end

    def variant_selection_deferred?
      part_options[:variant_selection_deferred]
    end

    def quantity
      part_options[:count].to_i
    end

    def assemblies_part
      @assemblies_part ||= begin
        if given_id?
          Spree::AssembliesPart.find(part_options[:id])
        else
          Spree::AssembliesPart.find_or_initialize_by(
            variant_selection_deferred: variant_selection_deferred?,
            assembly_id: assembly_id,
            part_id: part_id
          )
        end
      end
    end
  end
end
