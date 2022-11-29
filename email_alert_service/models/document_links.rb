class DocumentLinks
  attr_reader :document

  def initialize(document)
    @document = document
  end

  def self.call(...)
    new(...).links
  end

  def links
    reverse_links_hash.merge("taxon_tree" => taxon_tree)
  end

private

  def taxons
    document.dig("expanded_links", "taxons").to_a
  end

  def reverse_links_hash
    expanded_links_keys.each_with_object({}) do |key, hash|
      expanded_links_values = document.dig("expanded_links", key)
      content_ids = expanded_links_values.map { |i| i["content_id"] }
      hash[key] = content_ids
    end
  end

  def raw_expanded_links_keys
    document.fetch("expanded_links", {}).keys
  end

  def expanded_links_keys
    raw_expanded_links_keys.tap { |k| k.delete("available_translations") }
  end

  def taxon_tree
    TaxonTree.ancestors(taxons)
  end
end
