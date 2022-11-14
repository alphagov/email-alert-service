class DocumentLinks
  attr_reader :document

  def initialize(document)
    @document = document
  end

  def self.call(args)
    new(args).links
  end

  def links
    document.fetch("links", {}).merge("taxon_tree" => taxon_tree)
  end

private

  def taxons
    document.dig("expanded_links", "taxons").to_a
  end

  def taxon_tree
    TaxonTree.ancestors(taxons)
  end
end
