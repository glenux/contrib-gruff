# frozen_string_literal: true

# rbs_inline: enabled

# @private
class Gruff::LabelPlacement::ResolutionResult
  attr_reader :labels #: Array[Gruff::LabelPlacement::PlacedLabel]
  attr_reader :unresolved_pairs #: Array[[Gruff::LabelPlacement::PlacedLabel, Gruff::LabelPlacement::PlacedLabel]]
  attr_reader :iteration_count #: Integer
  attr_reader :stopped_reason #: Symbol

  # @rbs labels: Array[Gruff::LabelPlacement::PlacedLabel]
  # @rbs unresolved_pairs: Array[[Gruff::LabelPlacement::PlacedLabel, Gruff::LabelPlacement::PlacedLabel]]
  # @rbs iteration_count: Integer
  # @rbs stopped_reason: Symbol
  # @rbs return: void
  def initialize(labels:, unresolved_pairs:, iteration_count:, stopped_reason:)
    @labels = labels
    @unresolved_pairs = unresolved_pairs
    @iteration_count = iteration_count
    @stopped_reason = stopped_reason
  end

  # @rbs return: bool
  def resolved?
    unresolved_pairs.empty?
  end

  # @rbs return: bool
  def unresolved?
    !resolved?
  end

  # @rbs return: Array[String | Symbol | Integer]
  def unresolved_label_ids
    unresolved_pairs.flatten.map(&:id).uniq
  end
end
