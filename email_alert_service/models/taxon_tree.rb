class TaxonTree
  # Return all the taxons and ancestors of those taxons
  def self.ancestors(taxons)
    taxons.flat_map { |taxon| [taxon["content_id"]] + parent_taxon_tree(taxon) }.uniq
  end

  def self.parent_taxon_tree(taxon)
    return [] unless taxon.dig("links", "parent_taxons")

    taxon["links"]["parent_taxons"].flat_map do |parent_taxon|
      [parent_taxon["content_id"]] + parent_taxon_tree(parent_taxon)
    end
  end
end
