# frozen_string_literal: true

# rbs_inline: enabled

# @private
class Gruff::LabelPlacement::PieMoveBelowMedianOffsetStrategy < Gruff::LabelPlacement::PieStrategy
private

  # @rbs first: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs second: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs return: Array[Gruff::LabelPlacement::PiePlacedLabel]
  def tie_breaker_labels(first, second)
    median = median_offset
    below_median_labels = [first, second].select do |label|
      offsets_by_label_id[label.id] < median
    end

    return [smaller_slice_label(first, second)] if below_median_labels.empty?
    return [below_median_labels.first] if below_median_labels.length == 1

    [smaller_slice_label(*below_median_labels)]
  end
end
