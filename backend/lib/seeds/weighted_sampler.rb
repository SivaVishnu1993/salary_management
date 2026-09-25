module Seeds
  # Picks keys from a { key => weight } hash in proportion to their weights,
  # using an injected Random so results are reproducible.
  class WeightedSampler
    def initialize(weights, rng:)
      @keys = weights.keys
      @cumulative = weights.values.each_with_object([]) { |weight, acc| acc << (acc.last.to_i + weight) }
      @rng = rng
    end

    def sample
      ticket = rng.rand(cumulative.last)
      keys[cumulative.bsearch_index { |upper| upper > ticket }]
    end

    private

    attr_reader :keys, :cumulative, :rng
  end
end
