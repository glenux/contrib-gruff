# frozen_string_literal: true
# rbs_inline: enabled

require_relative 'gruff_test_case'

class TestGruffPie < GruffTestCase
  def setup
    @datasets = [
      [:Darren, [25]],
      [:Chris, [80]],
      [:Egbert, [22]],
      [:Adam, [95]],
      [:Bill, [90]],
      ['Frank', [5]],
      ['Zero', [0]]
    ]
  end

  def test_pie_graph
    g = Gruff::Pie.new
    g.title = 'Visual Pie Graph Test'
    @datasets.each do |data|
      g.data(data[0], data[1])
    end

    # Default theme
    g.write('test/output/pie_keynote.png')

    assert_same_image('test/expected/pie_keynote.png', 'test/output/pie_keynote.png')
  end

  def test_pie_graph_greyscale
    g = Gruff::Pie.new
    g.title = 'Greyscale Pie Graph Test'
    g.theme = Gruff::Themes::GREYSCALE
    @datasets.each do |data|
      g.data(data[0], data[1])
    end

    # Default theme
    g.write('test/output/pie_grey.png')

    assert_same_image('test/expected/pie_grey.png', 'test/output/pie_grey.png')
  end

  def test_pie_graph_pastel
    g = Gruff::Pie.new
    g.theme = Gruff::Themes::PASTEL
    g.title = 'Pastel Pie Graph Test'
    @datasets.each do |data|
      g.data(data[0], data[1])
    end

    # Default theme
    g.write('test/output/pie_pastel.png')

    assert_same_image('test/expected/pie_pastel.png', 'test/output/pie_pastel.png')
  end

  def test_pie_graph_small
    g = Gruff::Pie.new(400)
    g.title = 'Visual Pie Graph Test Small'
    @datasets.each do |data|
      g.data(data[0], data[1])
    end

    # Default theme
    g.write('test/output/pie_keynote_small.png')

    assert_same_image('test/expected/pie_keynote_small.png', 'test/output/pie_keynote_small.png')
  end

  def test_pie_graph_nearly_equal
    g = Gruff::Pie.new
    g.title = 'Pie Graph Nearly Equal'

    g.data(:Blake, [41])
    g.data(:Aaron, [42])

    g.write('test/output/pie_nearly_equal.png')

    assert_same_image('test/expected/pie_nearly_equal.png', 'test/output/pie_nearly_equal.png')
  end

  def test_pie_graph_equal
    g = Gruff::Pie.new
    g.title = 'Pie Graph Equal'

    g.data(:Bert, [41])
    g.data(:Adam, [41])

    g.write('test/output/pie_equal.png')

    assert_same_image('test/expected/pie_equal.png', 'test/output/pie_equal.png')
  end

  def test_pie_graph_zero
    g = Gruff::Pie.new
    g.title = 'Pie Graph One Zero'

    g.data(:Bert, [0])
    g.data(:Adam, [1])

    g.write('test/output/pie_zero.png')

    assert_same_image('test/expected/pie_zero.png', 'test/output/pie_zero.png')
  end

  def test_pie_graph_one_val
    g = Gruff::Pie.new
    g.title = 'Pie Graph One Val'

    g.data(:Bert, 53)
    g.data(:Adam, 29)

    g.write('test/output/pie_one_val.png')

    assert_same_image('test/expected/pie_one_val.png', 'test/output/pie_one_val.png')
  end

  def test_single_value_inputs_keep_their_existing_slice_values
    g = Gruff::Pie.new
    g.sort = false
    g.data('Scalar', 53)
    g.data('Single Element Array', [29])

    g.__send__(:setup_data)

    slices = g.__send__(:slices)

    assert_equal [53, 29], slices.map(&:value)
    assert_equal [Integer, Integer], slices.map { |slice| slice.value.class }
  end

  def test_multi_point_inputs_use_summed_values_for_slices_and_sorting
    g = Gruff::Pie.new
    g.data('Small', [2, 1])
    g.data('Large', [10, 15, 5])
    g.data('Medium', [7, 5])

    g.__send__(:setup_data)

    slices = g.__send__(:slices)

    assert_equal %w[Large Medium Small], slices.map(&:label)
    assert_equal [30, 12, 3], slices.map(&:value)
  end

  def test_mixed_signed_points_are_allowed_when_slice_sum_is_nonnegative
    g = Gruff::Pie.new
    g.sort = false
    g.data('Mixed', [10, -5])
    g.data('Other', [5])

    g.__send__(:setup_data)

    slices = g.__send__(:slices)

    assert_equal %w[Mixed Other], slices.map(&:label)
    assert_equal [5, 5], slices.map(&:value)
  end

  def test_negative_summed_slice_is_rejected
    g = Gruff::Pie.new
    g.data('Bad', [10, -20])
    g.data('Good', [30])

    error = assert_raises(ArgumentError) do
      g.to_image
    end

    assert_equal 'Pie chart cannot contain a slice with a negative sum', error.message
  end

  def test_nonpositive_total_is_rejected
    g = Gruff::Pie.new
    g.data('A', 0)
    g.data('B', [0, 0])

    error = assert_raises(ArgumentError) do
      g.to_image
    end

    assert_equal 'Pie chart total must be greater than 0', error.message
  end

  def test_no_data
    g = Gruff::Pie.new
    g.title = 'No Data'
    # Default theme
    g.write('test/output/pie_no_data.png')

    assert_same_image('test/expected/pie_no_data.png', 'test/output/pie_no_data.png')

    g = Gruff::Pie.new
    g.title = 'No Data Title'
    g.no_data_message = 'There is no data'
    g.write('test/output/pie_no_data_msg.png')

    assert_same_image('test/expected/pie_no_data_msg.png', 'test/output/pie_no_data_msg.png')

    g = Gruff::Pie.new
    g.data 'A', []
    g.data 'B', []
    g.write('test/output/pie_no_data_with_empty.png')

    assert_same_image('test/expected/pie_no_data_with_empty.png', 'test/output/pie_no_data_with_empty.png')
  end

  def test_wide
    g = setup_basic_graph('800x400')
    g.title = 'Wide Pie'
    g.write('test/output/pie_wide.png')

    assert_same_image('test/expected/pie_wide.png', 'test/output/pie_wide.png')
  end

  def test_label_size
    g = setup_basic_graph
    g.title = 'Pie With Small Legend'
    g.legend_font_size = 10
    g.write('test/output/pie_legend.png')

    assert_same_image('test/expected/pie_legend.png', 'test/output/pie_legend.png')

    g = setup_basic_graph(400)
    g.title = 'Small Pie With Small Legend'
    g.legend_font_size = 10
    g.write('test/output/pie_legend_small.png')

    assert_same_image('test/expected/pie_legend_small.png', 'test/output/pie_legend_small.png')
  end

  def test_tiny_simple_pie
    r = Random.new(297_427)
    @datasets = (1..5).map { ['Auto', [r.rand(100)]] }

    g = setup_basic_graph 200
    g.hide_legend = true
    g.hide_title = true
    g.hide_line_numbers = true

    g.marker_font_size = 40.0
    g.minimum_value = 0.0

    write_test_file(g, 'pie_simple.png')

    assert_same_image('test/expected/pie_simple.png', 'test/output/pie_simple.png')
  end

  def test_pie_with_adjusted_text_offset_percentage
    g = setup_basic_graph
    g.title = 'Adjusted Text Offset Percentage'
    g.text_offset_percentage = 0.03
    g.write('test/output/pie_adjusted_text_offset_percentage.png')

    assert_same_image('test/expected/pie_adjusted_text_offset_percentage.png', 'test/output/pie_adjusted_text_offset_percentage.png')
  end

  def test_label_format
    g = setup_basic_graph
    g.title = 'Label format'
    g.label_formatting = lambda do |value, percentage|
      "#{value} (#{percentage}%)"
    end

    g.write('test/output/pie_label_format.png')

    assert_same_image('test/expected/pie_label_format.png', 'test/output/pie_label_format.png')
  end

  def test_small_slice_labels_are_readable
    g = Gruff::Pie.new(400)
    g.title = 'Small Slice Labels'
    g.sort = false
    g.marker_font_size = 40.0

    10.times do |index|
      g.data("Slice #{index + 1}", 4)
    end
    g.data('Large', 80)

    g.write('test/output/pie_small_slice_labels.png')

    assert_same_image('test/expected/pie_small_slice_labels.png', 'test/output/pie_small_slice_labels.png')
  end

  def test_label_placement_strategy_accepts_known_values
    g = Gruff::Pie.new

    assert_equal Gruff::LabelPlacement::PieMoveBothStrategy, g.__send__(:label_placement_strategy_class)

    g.label_placement_strategy = :move_smaller_slice

    assert_equal Gruff::LabelPlacement::PieMoveSmallerSliceStrategy, g.__send__(:label_placement_strategy_class)

    g.label_placement_strategy = 'move_below_median_offset'

    assert_equal Gruff::LabelPlacement::PieMoveBelowMedianOffsetStrategy, g.__send__(:label_placement_strategy_class)
  end

  def test_label_placement_strategy_rejects_unknown_values
    g = Gruff::Pie.new

    error = assert_raises(ArgumentError) do
      g.label_placement_strategy = :unknown
    end

    assert_equal 'Unknown label placement strategy: :unknown', error.message
  end

  def test_position_labels_preserves_coordinates_for_each_public_strategy_when_labels_do_not_collide
    Gruff::Pie::LABEL_PLACEMENT_STRATEGIES.each do |strategy|
      g = build_label_placement_test_graph(strategy)
      g.sort = false
      g.data('Small', 25)
      g.data('Large', 75)

      labels = prepared_positionable_labels_for(g)
      original_coordinates = labels.map { |label| [label.id, label.x, label.y] }

      positioned_coordinates = g.__send__(:position_labels, labels).map { |label| [label.id, label.x, label.y] }

      assert_equal original_coordinates, positioned_coordinates, "Expected #{strategy} to preserve already valid label coordinates"
      refute labels.any?(&:moved), "Expected #{strategy} not to mark non-colliding labels as moved"
      assert_instance_of Gruff::LabelPlacement::ResolutionResult, g.last_label_placement_result
      assert_predicate g.last_label_placement_result, :resolved?
    end
  end

  def test_position_labels_stores_the_last_label_placement_result
    g = Gruff::Pie.new(400)
    g.sort = false
    g.data('Small', 25)
    g.data('Large', 75)

    g.__send__(:setup_data)
    g.__send__(:setup_drawing)

    labels = []
    g.__send__(:slices).each do |slice|
      label = g.__send__(:process_label_for, slice, labels.length)
      labels << label if label
      g.__send__(:update_chart_degrees_with, slice.degrees)
    end

    g.__send__(:position_labels, labels)

    assert_instance_of Gruff::LabelPlacement::ResolutionResult, g.last_label_placement_result
    assert_predicate g.last_label_placement_result, :resolved?
  end

  def test_move_both_strategy_prefers_the_first_label_when_one_step_resolves_a_tied_collision
    g = build_label_placement_test_graph(:move_both)
    labels = [
      build_strategy_label(0, x: 100.0, angle: 180.0, slice_degrees: 40.0),
      build_strategy_label(1, x: 137.0, angle: 0.0, slice_degrees: 20.0)
    ]

    g.__send__(:position_labels, labels)

    moved_label_ids = labels.filter_map { |label| label.id if label.moved }

    assert_equal [0], moved_label_ids
    assert_operator labels[0].offset, :>, 0.0
    assert_in_delta 0.0, labels[1].offset
    assert_predicate g.last_label_placement_result, :resolved?
  end

  def test_move_smaller_slice_strategy_prefers_the_smaller_slice_when_one_step_resolves_a_tied_collision
    g = build_label_placement_test_graph(:move_smaller_slice)
    labels = [
      build_strategy_label(0, x: 100.0, angle: 180.0, slice_degrees: 40.0),
      build_strategy_label(1, x: 137.0, angle: 0.0, slice_degrees: 20.0)
    ]

    g.__send__(:position_labels, labels)

    moved_label_ids = labels.filter_map { |label| label.id if label.moved }

    assert_equal [1], moved_label_ids
    assert_in_delta 0.0, labels[0].offset
    assert_operator labels[1].offset, :>, 0.0
    assert_predicate g.last_label_placement_result, :resolved?
  end

  def test_move_below_median_offset_strategy_prefers_the_label_below_the_median_offset
    g = build_label_placement_test_graph(:move_below_median_offset)
    labels = [
      build_strategy_label(0, x: 100.0, angle: 180.0, slice_degrees: 40.0, offset: 0.0),
      build_strategy_label(1, x: 117.0, angle: 0.0, slice_degrees: 20.0, offset: 20.0),
      build_strategy_label(2, x: 300.0, angle: 0.0, slice_degrees: 60.0, offset: 10.0)
    ]

    g.__send__(:position_labels, labels)

    assert_operator labels[0].offset, :>, 0.0
    assert_in_delta 20.0, labels[1].offset
    assert_in_delta 0.0, labels[2].offset
    assert_predicate g.last_label_placement_result, :resolved?
  end

  def test_draw_positioned_labels_only_draws_connectors_for_labels_moved_by_the_selected_strategy
    g = build_label_placement_test_graph(:move_smaller_slice)
    labels = [
      build_strategy_label(0, x: 100.0, angle: 180.0, slice_degrees: 40.0),
      build_strategy_label(1, x: 137.0, angle: 0.0, slice_degrees: 20.0)
    ]
    positioned_labels = g.__send__(:position_labels, labels)
    connector_ids = []
    rendered_texts = []

    g.stub(:draw_label_connector, lambda { |label|
      connector_ids << label.id
    }) do
      g.stub(:draw_label_at, lambda { |_width, _height, _x, _y, text, **_kwargs|
        rendered_texts << text
      }) do
        g.__send__(:draw_positioned_labels, positioned_labels)
      end
    end

    assert_equal [1], connector_ids
    assert_equal %w[0 1], rendered_texts
  end

  def test_position_labels_exposes_unresolved_collisions_when_the_selected_strategy_cannot_make_progress
    g = build_label_placement_test_graph(:move_smaller_slice)
    labels = [
      build_strategy_label(0, x: 773.0, angle: 0.0, slice_degrees: 40.0),
      build_strategy_label(1, x: 797.0, angle: 0.0, slice_degrees: 20.0)
    ]

    g.__send__(:position_labels, labels)
    unresolved_pairs = g.last_label_placement_result.unresolved_pairs.map { |first, second| [first.id, second.id] }

    assert_equal :no_progress, g.last_label_placement_result.stopped_reason
    assert_predicate g.last_label_placement_result, :unresolved?
    assert_equal [[0, 1]], unresolved_pairs
    assert_equal [0, 1], g.last_label_placement_result.unresolved_label_ids.sort
  end

  def test_zero_degree
    g = setup_basic_graph
    g.title = 'zero_degree'
    g.zero_degree = 90
  end

  def test_start_degree
    g = setup_basic_graph
    g.title = 'start_degree'
    g.start_degree = 90

    g.write('test/output/pie_start_degree.png')

    assert_same_image('test/expected/pie_start_degree.png', 'test/output/pie_start_degree.png')
  end

  def test_empty_data
    g = Gruff::Pie.new
    g.title = 'Contained Empty Data'
    g.data 'A', 20
    g.data 'B', 35
    g.data 'C', nil
    g.data 'D', 50

    g.write('test/output/pie_empty_data.png')

    assert_same_image('test/expected/pie_empty_data.png', 'test/output/pie_empty_data.png')
  end

  def test_duck_typing
    g = Gruff::Pie.new
    g.data :A, GruffCustomData.new([25]), '#113285'
    g.data :B, GruffCustomData.new([20]), '#86A697'
    g.data :C, GruffCustomData.new([55]), '#E03C8A'
    g.write('test/output/pie_duck_typing.png')

    assert_same_image('test/expected/pie_duck_typing.png', 'test/output/pie_duck_typing.png')
  end

protected

  def setup_basic_graph(size = 800)
    g = Gruff::Pie.new(size)
    g.title = 'My Graph Title'
    @datasets.each do |data|
      g.data(data[0], data[1])
    end

    g
  end

  def build_label_placement_test_graph(strategy = nil, size = 400)
    g = Gruff::Pie.new(size)
    g.font = File.join(fixtures_dir, 'Roboto-Light.ttf')
    g.label_placement_strategy = strategy if strategy
    g
  end

  def prepared_positionable_labels_for(graph)
    graph.__send__(:setup_data)
    graph.__send__(:setup_drawing)

    labels = []
    graph.__send__(:slices).each do |slice|
      next if slice.value <= 0

      label = graph.__send__(:process_label_for, slice, labels.length)
      labels << label if label
      graph.__send__(:update_chart_degrees_with, slice.degrees)
    end

    labels
  end

  def build_strategy_label(id, x:, angle:, slice_degrees:, offset: 0.0, y: 100.0)
    Gruff::LabelPlacement::PiePlacedLabel.new(
      id: id,
      text: id.to_s,
      x: x,
      y: y,
      width: 40.0,
      height: 20.0,
      order: id,
      angle: angle,
      base_x: x,
      base_y: y,
      color: '#000000',
      slice_degrees: slice_degrees,
      slice_value: slice_degrees
    ).tap do |label|
      label.offset = offset
    end
  end
end
