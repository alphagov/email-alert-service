class DocumentLinks
  attr_reader :document

  def initialize(document)
    @document = document
  end

  def self.call(args)
    new(args).links
  end

  def links
    document.fetch("links", {}).merge(
      "taxon_tree" => taxon_tree,
      "document_collections" => document_collection_ids,
    )
  end

private

  def taxons
    document.dig("expanded_links", "taxons").to_a
  end

  def document_collections
    document.dig("expanded_links", "document_collections").to_a
  end

  def document_collection_ids
    document_collections.map { |o| o["content_id"] }
  end

  def taxon_tree
    TaxonTree.ancestors(taxons)
  end
end
