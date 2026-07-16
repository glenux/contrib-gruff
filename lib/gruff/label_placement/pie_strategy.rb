# frozen_string_literal: true

# rbs_inline: enabled

# @private
class Gruff::LabelPlacement::PieStrategy < Gruff::LabelPlacement::PlacementStrategy
  # @rbs max_x: Float | Integer
  # @rbs max_y: Float | Integer
  # @rbs collision_detector: Gruff::LabelPlacement::CollisionDetector
  # @rbs radial_step: Float | Integer
  # @rbs tightening_step: Float | Integer
  # @rbs max_iterations: Integer
  # @rbs debug_hook: nil | Proc
  # @rbs return: void
  def initialize(max_x:, max_y:, collision_detector:, radial_step:, tightening_step:, max_iterations:, debug_hook: nil)
    super(collision_detector: collision_detector, max_iterations: max_iterations, debug_hook: debug_hook)
    @max_x = max_x.to_f
    @max_y = max_y.to_f
    @radial_step = radial_step.to_f
    @tightening_step = tightening_step.to_f
  end

private

  attr_reader :offsets_by_label_id #: Hash[String | Symbol | Integer, Float]

  # @rbs labels: Array[Gruff::LabelPlacement::PiePlacedLabel]
  # @rbs return: void
  def prepare(labels)
    @offsets_by_label_id = Hash.new(0.0)

    labels.each do |label|
      @offsets_by_label_id[label.id] = label.offset.to_f
      apply_offset!(label, @offsets_by_label_id[label.id])
      label.moved = @offsets_by_label_id[label.id].positive?
    end
  end

  # @rbs label: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs _labels: Array[Gruff::LabelPlacement::PiePlacedLabel]
  # @rbs return: bool
  def can_move_label?(label, _labels)
    candidate = label.dup
    apply_offset!(candidate, @offsets_by_label_id[label.id] + @radial_step)
    within_canvas?(candidate)
  end

  # @rbs label: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs _labels: Array[Gruff::LabelPlacement::PiePlacedLabel]
  # @rbs return: void
  def move_label!(label, _labels)
    next_offset = @offsets_by_label_id[label.id] + @radial_step
    @offsets_by_label_id[label.id] = next_offset
    apply_offset!(label, next_offset)
    label.moved = true
  end

  # @rbs labels: Array[Gruff::LabelPlacement::PiePlacedLabel]
  # @rbs return: void
  def tighten(labels)
    labels.each do |label|
      next unless @offsets_by_label_id[label.id].positive?

      while @offsets_by_label_id[label.id] > 0.0
        tightened_offset = [@offsets_by_label_id[label.id] - @tightening_step, 0.0].max
        candidate = label.dup
        apply_offset!(candidate, tightened_offset)
        break unless within_canvas?(candidate)

        candidate_labels = labels.map { |current| current.id == label.id ? candidate : current }
        break if @collision_detector.collides_with_any?(candidate_labels, candidate)

        @offsets_by_label_id[label.id] = tightened_offset
        label.x = candidate.x
        label.y = candidate.y
        label.offset = tightened_offset
        label.moved = tightened_offset.positive?
      end
    end
  end

  # @rbs label: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs offset: Float | Integer
  # @rbs return: void
  def apply_offset!(label, offset)
    angle = deg2rad(label.angle)

    label.x = label.base_x + (offset * Math.cos(angle))
    label.y = label.base_y + (offset * Math.sin(angle))
    label.offset = offset.to_f
  end

  # @rbs label: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs return: bool
  def within_canvas?(label)
    label.left >= 0.0 &&
      label.right <= @max_x &&
      label.top >= 0.0 &&
      label.bottom <= @max_y
  end

  # @rbs angle: Float | Integer
  # @rbs return: Float
  def deg2rad(angle)
    angle.to_f * (Math::PI / 180.0)
  end

  # @rbs first: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs second: Gruff::LabelPlacement::PiePlacedLabel
  # @rbs return: Gruff::LabelPlacement::PiePlacedLabel
  def smaller_slice_label(first, second)
    first_degrees = first.slice_degrees
    second_degrees = second.slice_degrees

    return first if first_degrees < second_degrees
    return second if second_degrees < first_degrees

    first_offset = @offsets_by_label_id[first.id]
    second_offset = @offsets_by_label_id[second.id]

    return first if first_offset < second_offset
    return second if second_offset < first_offset

    first.order <= second.order ? first : second
  end

  # @rbs return: Float
  def median_offset
    offsets = @offsets_by_label_id.values.sort
    return 0.0 if offsets.empty?

    midpoint = offsets.length / 2
    return offsets[midpoint].to_f if offsets.length.odd?

    (offsets[midpoint - 1].to_f + offsets[midpoint].to_f) / 2.0
  end
end
