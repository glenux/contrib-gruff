# frozen_string_literal: true

# rbs_inline: enabled

# @private
class Gruff::LabelPlacement::PieMoveSmallerSliceStrategy < Gruff::LabelPlacement::PieStrategy
private

  # @rbs first: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs second: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs return: Array[Gruff::LabelPlacement::PiePlacedLabel]
  def tie_breaker_labels(first, second)
    [smaller_slice_label(first, second)]
  end
end
