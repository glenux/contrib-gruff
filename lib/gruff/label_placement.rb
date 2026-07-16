# frozen_string_literal: true

# rbs_inline: enabled

# @private
module Gruff::LabelPlacement
  autoload :CollisionDetector, Gruff.libpath('label_placement/collision_detector')
  autoload :PieMoveBelowMedianOffsetStrategy, Gruff.libpath('label_placement/pie_move_below_median_offset_strategy')
  autoload :PieMoveBothStrategy, Gruff.libpath('label_placement/pie_move_both_strategy')
  autoload :PiePlacedLabel, Gruff.libpath('label_placement/pie_placed_label')
  autoload :PieMoveSmallerSliceStrategy, Gruff.libpath('label_placement/pie_move_smaller_slice_strategy')
  autoload :PieStrategy, Gruff.libpath('label_placement/pie_strategy')
  autoload :PlacedLabel, Gruff.libpath('label_placement/placed_label')
  autoload :PlacementStrategy, Gruff.libpath('label_placement/placement_strategy')
  autoload :ResolutionResult, Gruff.libpath('label_placement/resolution_result')
end
