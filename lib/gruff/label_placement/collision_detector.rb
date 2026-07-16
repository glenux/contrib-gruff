# frozen_string_literal: true

# rbs_inline: enabled

# @private
class Gruff::LabelPlacement::CollisionDetector
  # @rbs padding: Float | Integer
  # @rbs return: void
  def initialize(padding: 0.0)
    @padding = padding.to_f
  end

  # @rbs labels: Array[Gruff::LabelPlacement::PlacedLabel]
  # @rbs return: Array[[Gruff::LabelPlacement::PlacedLabel, Gruff::LabelPlacement::PlacedLabel]]
  def colliding_pairs(labels)
    pairs = []

    labels.each_with_index do |label, index|
      labels[(index + 1)..]&.each do |other|
        pairs << [label, other] if collides?(label, other)
      end
    end

    pairs
  end

  # @rbs labels: Array[Gruff::LabelPlacement::PlacedLabel]
  # @rbs return: Hash[String | Symbol | Integer, Integer]
  def collision_counts(labels)
    counts = Hash.new(0)

    colliding_pairs(labels).each do |first, second|
      counts[first.id] += 1
      counts[second.id] += 1
    end

    counts
  end

  # @rbs labels: Array[Gruff::LabelPlacement::PlacedLabel]
  # @rbs target: Gruff::LabelPlacement::PlacedLabel
  # @rbs return: bool
  def collides_with_any?(labels, target)
    labels.any? do |other|
      other.id != target.id && collides?(target, other)
    end
  end

  # @rbs first: Gruff::LabelPlacement::PlacedLabel
  # @rbs second: Gruff::LabelPlacement::PlacedLabel
  # @rbs return: bool
  def collides?(first, second)
    !(
      (first.right + @padding) <= second.left ||
      (second.right + @padding) <= first.left ||
      (first.bottom + @padding) <= second.top ||
      (second.bottom + @padding) <= first.top
    )
  end
end
