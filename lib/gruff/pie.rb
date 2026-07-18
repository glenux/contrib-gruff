# frozen_string_literal: true

# rbs_inline: enabled

#
# Here's how to make a Gruff::Pie.
#
#   g = Gruff::Pie.new
#   g.title = "Visual Pie Graph Test"
#   g.data 'Fries', 20
#   g.data 'Hamburgers', 50
#   g.write("pie_keynote.png")
#
# Each dataset becomes a single slice. When a dataset contains multiple
# points, the slice value is the sum of the full series.
#
# To control where the pie chart starts creating slices, use {#start_degree=}.
#
class Gruff::Pie < Gruff::Base
  DEFAULT_TEXT_OFFSET_PERCENTAGE = 0.1
  DEFAULT_LABEL_PLACEMENT_STRATEGY = :move_both
  LABEL_PLACEMENT_STRATEGIES = %i[move_both move_smaller_slice move_below_median_offset].freeze

  # Reserve a small visual gutter between label bounds.
  #
  # Text that only barely avoids overlapping still reads as crowded once
  # anti-aliasing is applied, so collision detection intentionally treats a
  # near-touching layout as unresolved.
  LABEL_COLLISION_PADDING = 4.0

  # Search outward in coarse increments first.
  #
  # The initial pass needs to separate dense groups quickly without spending too
  # many iterations nudging labels by single pixels. The tightening pass below
  # is responsible for reclaiming the extra space precisely once the collisions
  # are gone.
  RADIAL_LABEL_STEP = 8.0

  # Tighten one pixel at a time after the coarse search.
  #
  # This keeps the final placement deterministic and close to the pie instead of
  # relying on image snapshots to bless an arbitrary overshoot from the coarse
  # search step.
  RADIAL_LABEL_TIGHTENING_STEP = 1.0

  # Hard stop for pathological layouts.
  #
  # Label placement is heuristic, so the resolver needs a fixed budget to avoid
  # an endless search on charts that cannot be fully untangled inside the
  # available canvas. The resolution result exposes when this limit is hit.
  MAX_LABEL_POSITION_ITERATIONS = 100

  # Can be used to make the pie start cutting slices at the top (-90.0)
  # or at another angle. Default is +-90.0+, which starts at 3 o'clock.
  attr_writer :start_degree #: Float | Integer

  # Set the number output format lambda.
  attr_writer :label_formatting #: Proc

  # Do not show labels for slices that are less than this percent. Use 0 to always show all labels.
  # Defaults to +0+.
  attr_writer :hide_labels_less_than #: Float | Integer

  # Affect the distance between the percentages and the pie chart.
  # Defaults to +0.1+.
  attr_writer :text_offset_percentage #: Float | Integer

  ## Use values instead of percentages.
  attr_writer :show_values_as_labels #: bool

  # Set to +true+ if you want slices sorted by descending dataset totals.
  # Pie slices use the sum of each dataset's points. Default is +true+.
  attr_writer :sort #: bool

  # Details from the most recent label placement pass. This is primarily useful
  # when diagnosing collisions that the configured placement strategy could not resolve.
  attr_reader :last_label_placement_result #: nil | Gruff::LabelPlacement::ResolutionResult

  # Select how overlapping pie labels are repositioned.
  # Supported values are +:move_both+, +:move_smaller_slice+, and
  # +:move_below_median_offset+.
  # Defaults to +:move_both+.
  # @rbs value: Symbol | String
  # @rbs return: void
  def label_placement_strategy=(value)
    strategy = value.respond_to?(:to_sym) ? value.to_sym : value

    unless LABEL_PLACEMENT_STRATEGIES.include?(strategy)
      raise ArgumentError, "Unknown label placement strategy: #{value.inspect}"
    end

    @label_placement_strategy = strategy
  end

  # Can be used to make the pie start cutting slices at the top (-90.0)
  # or at another angle. Default is +-90.0+, which starts at 3 o'clock.
  # @deprecated Please use {#start_degree=} instead.
  # @rbs value: Float | Integer
  # @rbs return: void
  def zero_degree=(value)
    warn '#zero_degree= is deprecated. Please use `start_degree` attribute instead'
    @start_degree = value
  end

private

  # @rbs return: void
  def initialize_attributes
    super
    @start_degree = -90.0
    @hide_labels_less_than = 0.0
    @text_offset_percentage = DEFAULT_TEXT_OFFSET_PERCENTAGE
    @show_values_as_labels = false
    @marker_font.bold = true
    @sort = true
    @label_placement_strategy = DEFAULT_LABEL_PLACEMENT_STRATEGY
    @last_label_placement_result = nil

    @hide_line_markers = true
    @hide_line_markers.freeze

    @label_formatting = ->(value, percentage) { @show_values_as_labels ? value.to_s : "#{percentage}%" }
  end

  # @rbs return: void
  def setup_drawing
    @center_labels_over_point = false
    super
  end

  # @rbs return: void
  def draw_graph
    labels = []

    slices.each do |slice|
      if slice.value > 0
        Gruff::Renderer::Ellipse.new(renderer, color: slice.color, width: radius)
                                .render(center_x, center_y, radius / 2.0, radius / 2.0, chart_degrees, chart_degrees + slice.degrees + 0.5)
        label = process_label_for(slice, labels.length)
        labels << label if label
        update_chart_degrees_with slice.degrees
      end
    end

    draw_positioned_labels(position_labels(labels))
  end

  # @rbs return: Array[Gruff::Pie::PieSlice]
  def slices
    @slices ||= begin
      slices = store.data.map { |data| Gruff::Pie::PieSlice.new(data.label, data.points.compact.sum, data.color) }

      raise ArgumentError, 'Pie chart cannot contain a slice with a negative sum' if slices.any? { |slice| slice.value < 0 }

      slices = slices.sort_by { |slice| -slice.value.to_f } if @sort

      total = slices.sum(&:value).to_f
      raise ArgumentError, 'Pie chart total must be greater than 0' if total <= 0.0

      slices.each { |slice| slice.total = total }
    end
  end

  # General Helper Methods

  # @rbs degrees: Float | Integer
  # @rbs return: void
  def update_chart_degrees_with(degrees)
    @chart_degrees = chart_degrees + degrees
  end

  # Spatial Value-Related Methods

  # @rbs return: Float | Integer
  def chart_degrees
    @chart_degrees ||= @start_degree
  end

  attr_reader :graph_height #: Float | Integer
  attr_reader :graph_width #: Float | Integer

  # @rbs return: Float | Integer
  def half_width
    graph_width / 2.0
  end

  # @rbs return: Float | Integer
  def half_height
    graph_height / 2.0
  end

  # @rbs return: Float | Integer
  def radius
    @radius ||= ([graph_width, graph_height].min / 2.0) * 0.8
  end

  # @rbs return: Float | Integer
  def center_x
    @center_x ||= @graph_left + half_width
  end

  # @rbs return: Float | Integer
  def center_y
    @center_y ||= @graph_top + half_height - 10
  end

  # @rbs return: Float | Integer
  def distance_from_center
    20.0
  end

  # @rbs return: Float | Integer | BigDecimal
  def radius_offset
    radius + (radius * @text_offset_percentage) + distance_from_center
  end

  # @rbs return: Float | Integer
  def ellipse_factor
    radius_offset * @text_offset_percentage
  end

  # Label-Related Methods

  # @rbs slice: Gruff::Pie::PieSlice
  # @rbs index: Integer
  # @rbs return: nil | Gruff::LabelPlacement::PiePlacedLabel
  def process_label_for(slice, index)
    return if slice.percentage < @hide_labels_less_than

    x, y = label_coordinates_for(slice)
    label_text = truncate_label_text(@label_formatting.call(slice.value, slice.percentage).to_s)
    metrics = text_metrics(@marker_font, label_text)

    Gruff::LabelPlacement::PiePlacedLabel.new(
      id: index,
      text: label_text,
      x: x,
      y: y,
      width: metrics.width,
      height: metrics.height,
      order: index,
      color: slice.color,
      angle: chart_degrees + (slice.degrees / 2.0),
      base_x: x,
      base_y: y,
      slice_degrees: slice.degrees,
      slice_value: slice.value
    )
  end

  # @rbs labels: Array[Gruff::LabelPlacement::PiePlacedLabel]
  # @rbs return: Array[Gruff::LabelPlacement::PiePlacedLabel]
  def position_labels(labels)
    @last_label_placement_result = nil
    build_label_placement_strategy.resolve(labels)
  end

  # @rbs return: Gruff::LabelPlacement::PlacementStrategy
  def build_label_placement_strategy
    label_placement_strategy_class.new(
      max_x: label_placement_max_x,
      max_y: label_placement_max_y,
      collision_detector: Gruff::LabelPlacement::CollisionDetector.new(padding: LABEL_COLLISION_PADDING),
      radial_step: RADIAL_LABEL_STEP,
      tightening_step: RADIAL_LABEL_TIGHTENING_STEP,
      max_iterations: MAX_LABEL_POSITION_ITERATIONS,
      debug_hook: lambda { |result| @last_label_placement_result = result }
    )
  end

  # @rbs return: Float | Integer
  def label_placement_max_x
    @columns / @scale
  end

  # @rbs return: Float | Integer
  def label_placement_max_y
    @rows / @scale
  end

  # @rbs return: untyped
  def label_placement_strategy_class
    case @label_placement_strategy
    when :move_both
      Gruff::LabelPlacement::PieMoveBothStrategy
    when :move_smaller_slice
      Gruff::LabelPlacement::PieMoveSmallerSliceStrategy
    when :move_below_median_offset
      Gruff::LabelPlacement::PieMoveBelowMedianOffsetStrategy
    else
      raise ArgumentError, "Unknown label placement strategy: #{@label_placement_strategy.inspect}"
    end
  end

  # @rbs labels: Array[Gruff::LabelPlacement::PiePlacedLabel]
  # @rbs return: void
  def draw_positioned_labels(labels)
    labels.each do |label|
      draw_label_connector(label) if label.moved
      draw_label_at(1.0, 1.0, label.x, label.y, label.text, gravity: Magick::CenterGravity)
    end
  end

  # @rbs label: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs return: void
  def draw_label_connector(label)
    angle = deg2rad(label.angle)
    unit_x = Math.cos(angle)
    unit_y = Math.sin(angle)
    start_x = center_x + (radius * unit_x)
    start_y = center_y + (radius * unit_y)
    end_x, end_y = label_connector_endpoint(label, unit_x, unit_y)

    Gruff::Renderer::Line.new(renderer, color: label.color).render(start_x, start_y, end_x, end_y)
  end

  # @rbs label: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs unit_x: Float
  # @rbs unit_y: Float
  # @rbs return: [Float, Float]
  def label_connector_endpoint(label, unit_x, unit_y)
    half_width = label.width / 2.0
    half_height = label.height / 2.0
    scales = []

    scales << (half_width / unit_x.abs) unless unit_x.zero?
    scales << (half_height / unit_y.abs) unless unit_y.zero?

    scale = (scales.min || 0.0) - 1.0
    scale = [scale, 0.0].max

    [
      label.x - (unit_x * scale),
      label.y - (unit_y * scale)
    ]
  end

  # @rbs slice: Gruff::Pie::PieSlice
  # @rbs return: [Float | Integer, Float | Integer]
  def label_coordinates_for(slice)
    angle = chart_degrees + (slice.degrees / 2.0)

    [x_label_coordinate(angle), y_label_coordinate(angle)]
  end

  # @rbs angle: Float | Integer
  # @rbs return: Float
  def x_label_coordinate(angle)
    center_x + ((radius_offset + ellipse_factor) * Math.cos(deg2rad(angle))) #: Float
  end

  # @rbs angle: Float | Integer
  # @rbs return: Float
  def y_label_coordinate(angle)
    center_y + (radius_offset * Math.sin(deg2rad(angle)))
  end

  # Helper Classes
  #
  # @private
  class PieSlice
    attr_accessor :label #: String | Symbol
    attr_accessor :value #: Float | Integer
    attr_accessor :color #: String
    attr_accessor :total #: Float | Integer

    # @rbs label: String | Symbol
    # @rbs value: nil | Float | Integer
    # @rbs color: String
    # @rbs return: void
    def initialize(label, value, color)
      @label = label
      @value = value || 0.0
      @color = color
    end

    # @rbs return: Float | Integer
    def percentage
      (size * 100.0).round
    end

    # @rbs return: Float
    def degrees
      size * 360.0
    end

  private

    # @rbs return: Float | Integer
    def size
      value / total
    end
  end
end
