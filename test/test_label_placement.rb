# frozen_string_literal: true
# rbs_inline: enabled

require_relative 'gruff_test_case'

class TestLabelPlacement < Minitest::Test
  def test_collision_detector_returns_colliding_pairs_and_counts
    detector = Gruff::LabelPlacement::CollisionDetector.new(padding: Gruff::Pie::LABEL_COLLISION_PADDING)
    labels = [
      build_generic_label(0, x: 100.0),
      build_generic_label(1, x: 132.0),
      build_generic_label(2, x: 164.0)
    ]

    assert_equal [[0, 1], [1, 2]], detector.colliding_pairs(labels).map { |first, second| [first.id, second.id] }

    counts = detector.collision_counts(labels)
    assert_equal 1, counts[0]
    assert_equal 2, counts[1]
    assert_equal 1, counts[2]
  end

  def test_collision_padding_treats_nearly_touching_labels_as_colliding
    detector = Gruff::LabelPlacement::CollisionDetector.new(padding: Gruff::Pie::LABEL_COLLISION_PADDING)
    first = build_generic_label(0, x: 100.0)
    visible_gap = build_generic_label(1, x: 100.0 + 40.0 + Gruff::Pie::LABEL_COLLISION_PADDING)
    almost_touching = build_generic_label(2, x: visible_gap.x - 1.0)

    refute detector.collides?(first, visible_gap)
    assert detector.collides?(first, almost_touching)
  end

  def test_radial_step_moves_a_pie_label_by_exactly_one_outward_search_step
    strategy = build_strategy(Gruff::LabelPlacement::PieMoveBothStrategy)
    label = build_label(0, x: 100.0)

    strategy.send(:prepare, [label])
    strategy.send(:move_label!, label, [label])

    assert_equal Gruff::Pie::RADIAL_LABEL_STEP, label.offset
    assert_in_delta 100.0 + Gruff::Pie::RADIAL_LABEL_STEP, label.x, 0.001
    assert_in_delta 100.0, label.y, 0.001
  end

  def test_tightening_step_reclaims_only_the_last_safe_pixel_of_offset
    detector = Gruff::LabelPlacement::CollisionDetector.new(padding: Gruff::Pie::LABEL_COLLISION_PADDING)
    strategy = build_strategy(Gruff::LabelPlacement::PieMoveBothStrategy)
    fixed = build_label(0, x: 100.0)
    moved = build_label(1, x: 133.0, offset: 20.0)

    strategy.send(:prepare, [fixed, moved])
    strategy.send(:tighten, [fixed, moved])

    assert_equal 11.0, moved.offset
    refute detector.collides?(fixed, moved)

    one_pixel_closer = moved.dup
    strategy.send(:apply_offset!, one_pixel_closer, moved.offset - Gruff::Pie::RADIAL_LABEL_TIGHTENING_STEP)
    assert detector.collides?(fixed, one_pixel_closer)
  end

  def test_max_iterations_stops_an_endless_search_and_reports_the_budget_exhaustion
    max_iterations = Gruff::Pie::MAX_LABEL_POSITION_ITERATIONS
    strategy = fallback_strategy(
      { 0 => Array.new(max_iterations) { [100.0, 100.0] } },
      max_iterations: max_iterations
    )
    labels = [
      build_generic_label(0, x: 100.0),
      build_generic_label(1, x: 132.0)
    ]

    strategy.resolve(labels)
    result = strategy.last_resolution_result

    assert_equal max_iterations, result.iteration_count
    assert_equal :max_iterations, result.stopped_reason
    assert result.unresolved?
    assert_equal [0, 1], result.unresolved_label_ids.sort
  end

  def test_strategy_prioritizes_pairs_with_the_most_collisions
    strategy = build_strategy(Gruff::LabelPlacement::PieMoveSmallerSliceStrategy)
    labels = [
      build_label(0, x: 100.0, slice_degrees: 40.0),
      build_label(1, x: 132.0, slice_degrees: 30.0),
      build_label(2, x: 164.0, slice_degrees: 20.0)
    ]
    detector = Gruff::LabelPlacement::CollisionDetector.new(padding: Gruff::Pie::LABEL_COLLISION_PADDING)
    pairs = detector.colliding_pairs(labels)
    counts = detector.collision_counts(labels)

    first_pair, = strategy.send(:sorted_pairs, pairs, counts)
    selected_labels = strategy.send(:labels_for_pair, first_pair[0], first_pair[1], counts)

    assert_equal [1], selected_labels.map(&:id)
  end

  def test_move_both_strategy_moves_both_labels_on_equal_collision_counts
    strategy = build_strategy(Gruff::LabelPlacement::PieMoveBothStrategy)
    first = build_label(0, x: 100.0, slice_degrees: 40.0)
    second = build_label(1, x: 132.0, slice_degrees: 20.0)

    labels = strategy.send(:labels_for_pair, first, second, { 0 => 1, 1 => 1 })

    assert_equal [0, 1], labels.map(&:id)
  end

  def test_move_smaller_slice_strategy_moves_the_smaller_slice_on_equal_collision_counts
    strategy = build_strategy(Gruff::LabelPlacement::PieMoveSmallerSliceStrategy)
    first = build_label(0, x: 100.0, slice_degrees: 40.0)
    second = build_label(1, x: 132.0, slice_degrees: 20.0)

    strategy.send(:prepare, [first, second])
    labels = strategy.send(:labels_for_pair, first, second, { 0 => 1, 1 => 1 })

    assert_equal [1], labels.map(&:id)
  end

  def test_move_below_median_offset_strategy_moves_the_label_below_the_median_offset
    strategy = build_strategy(Gruff::LabelPlacement::PieMoveBelowMedianOffsetStrategy)
    first = build_label(0, x: 100.0, slice_degrees: 40.0, offset: 0.0)
    second = build_label(1, x: 132.0, slice_degrees: 20.0, offset: 20.0)
    third = build_label(2, x: 300.0, slice_degrees: 60.0, offset: 10.0)

    strategy.send(:prepare, [first, second, third])
    labels = strategy.send(:labels_for_pair, first, second, { 0 => 1, 1 => 1 })

    assert_equal [0], labels.map(&:id)
  end

  def test_move_below_median_offset_strategy_falls_back_to_the_smaller_slice
    strategy = build_strategy(Gruff::LabelPlacement::PieMoveBelowMedianOffsetStrategy)
    first = build_label(0, x: 100.0, slice_degrees: 40.0, offset: 0.0)
    second = build_label(1, x: 132.0, slice_degrees: 20.0, offset: 0.0)
    third = build_label(2, x: 300.0, slice_degrees: 60.0, offset: 0.0)

    strategy.send(:prepare, [first, second, third])
    labels = strategy.send(:labels_for_pair, first, second, { 0 => 1, 1 => 1 })

    assert_equal [1], labels.map(&:id)
  end

  def test_resolve_falls_back_to_the_other_label_when_the_preferred_label_cannot_finish_a_resolvable_chain
    detector = Gruff::LabelPlacement::CollisionDetector.new(padding: Gruff::Pie::LABEL_COLLISION_PADDING)
    strategy = fallback_strategy(
      {
        1 => [[148.0, 100.0]],
        2 => [[196.0, 100.0]]
      }
    )
    labels = [
      build_generic_label(0, x: 100.0),
      build_generic_label(1, x: 132.0),
      build_generic_label(2, x: 164.0)
    ]

    strategy.resolve(labels)

    assert_empty detector.colliding_pairs(labels)
    assert_equal [100.0, 148.0, 196.0], labels.map(&:x)
  end

  def test_resolve_exposes_unresolved_collisions_when_no_progress_is_possible
    emitted_results = []
    strategy = no_progress_strategy(debug_hook: lambda { |result| emitted_results << result })
    labels = [
      build_generic_label(0, x: 100.0),
      build_generic_label(1, x: 132.0)
    ]

    returned_labels = strategy.resolve(labels)
    result = strategy.last_resolution_result

    assert_same labels, returned_labels
    assert_same result, emitted_results.first
    assert_equal :no_progress, result.stopped_reason
    assert result.unresolved?
    assert_equal [[0, 1]], result.unresolved_pairs.map { |first, second| [first.id, second.id] }
    assert_equal [0, 1], result.unresolved_label_ids.sort
  end

private

  class FallbackStrategy < Gruff::LabelPlacement::PlacementStrategy
    # @rbs movements: Hash[Integer, Array[[Float, Float]]]
    # @rbs collision_detector: Gruff::LabelPlacement::CollisionDetector
    # @rbs max_iterations: Integer
    # @rbs debug_hook: nil | Proc
    # @rbs return: void
    def initialize(movements:, collision_detector:, max_iterations:, debug_hook: nil)
      super(collision_detector: collision_detector, max_iterations: max_iterations, debug_hook: debug_hook)
      @movements = movements.transform_values(&:dup)
    end

  private

    # @rbs first: Gruff::LabelPlacement::PlacedLabel
    # @rbs _second: Gruff::LabelPlacement::PlacedLabel
    # @rbs return: Array[Gruff::LabelPlacement::PlacedLabel]
    def tie_breaker_labels(first, _second)
      [first]
    end

    # @rbs label: Gruff::LabelPlacement::PlacedLabel
    # @rbs _labels: Array[Gruff::LabelPlacement::PlacedLabel]
    # @rbs return: bool
    def can_move_label?(label, _labels)
      @movements.fetch(label.id, []).any?
    end

    # @rbs label: Gruff::LabelPlacement::PlacedLabel
    # @rbs _labels: Array[Gruff::LabelPlacement::PlacedLabel]
    # @rbs return: void
    def move_label!(label, _labels)
      next_x, next_y = @movements.fetch(label.id).shift
      label.x = next_x
      label.y = next_y
    end
  end

  def build_generic_label(id, x:, y: 100.0)
    Gruff::LabelPlacement::PlacedLabel.new(
      id: id,
      text: id.to_s,
      x: x,
      y: y,
      width: 40.0,
      height: 20.0,
      order: id
    )
  end

  def build_label(id, x:, y: 100.0, slice_degrees: 10.0, offset: 0.0)
    Gruff::LabelPlacement::PiePlacedLabel.new(
      id: id,
      text: id.to_s,
      x: x,
      y: y,
      width: 40.0,
      height: 20.0,
      order: id,
      angle: 0.0,
      base_x: x,
      base_y: y,
      color: '#000000',
      slice_degrees: slice_degrees,
      slice_value: slice_degrees
    ).tap do |label|
      label.offset = offset
    end
  end

  def build_strategy(strategy_class, max_iterations: 10)
    strategy_class.new(
      max_x: 1000.0,
      max_y: 1000.0,
      collision_detector: Gruff::LabelPlacement::CollisionDetector.new(padding: Gruff::Pie::LABEL_COLLISION_PADDING),
      radial_step: Gruff::Pie::RADIAL_LABEL_STEP,
      tightening_step: Gruff::Pie::RADIAL_LABEL_TIGHTENING_STEP,
      max_iterations: max_iterations
    )
  end

  def fallback_strategy(movements, max_iterations: 10)
    FallbackStrategy.new(
      movements: movements,
      collision_detector: Gruff::LabelPlacement::CollisionDetector.new(padding: Gruff::Pie::LABEL_COLLISION_PADDING),
      max_iterations: max_iterations
    )
  end

  def no_progress_strategy(debug_hook: nil)
    FallbackStrategy.new(
      movements: {},
      collision_detector: Gruff::LabelPlacement::CollisionDetector.new(padding: Gruff::Pie::LABEL_COLLISION_PADDING),
      max_iterations: 10,
      debug_hook: debug_hook
    )
  end
end
