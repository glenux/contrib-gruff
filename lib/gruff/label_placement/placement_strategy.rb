# frozen_string_literal: true

# rbs_inline: enabled

# @private
class Gruff::LabelPlacement::PlacementStrategy
  attr_reader :last_resolution_result #: nil | Gruff::LabelPlacement::ResolutionResult

  # @rbs collision_detector: Gruff::LabelPlacement::CollisionDetector
  # @rbs max_iterations: Integer
  # @rbs debug_hook: nil | Proc
  # @rbs return: void
  def initialize(collision_detector:, max_iterations:, debug_hook: nil)
    @collision_detector = collision_detector
    @max_iterations = max_iterations
    @debug_hook = debug_hook
    @last_resolution_result = nil
  end

  # @rbs labels: Array[Gruff::LabelPlacement::PlacedLabel]
  # @rbs return: Array[Gruff::LabelPlacement::PlacedLabel]
  def resolve(labels)
    prepare(labels)
    iteration_count = 0
    stopped_reason = nil

    @max_iterations.times do |iteration|
      iteration_count = iteration + 1
      pairs = @collision_detector.colliding_pairs(labels)

      if pairs.empty?
        stopped_reason = :resolved
        break
      end

      collision_counts = @collision_detector.collision_counts(labels)
      moved_any = false

      sorted_pairs(pairs, collision_counts).each do |first, second|
        next unless move_pair(first, second, labels, collision_counts)

        moved_any = true
        break
      end

      unless moved_any
        stopped_reason = :no_progress
        break
      end
    end

    unresolved_pairs = @collision_detector.colliding_pairs(labels)

    if unresolved_pairs.empty?
      tighten(labels)
      unresolved_pairs = @collision_detector.colliding_pairs(labels)
      stopped_reason = unresolved_pairs.empty? ? :resolved : :tighten_reintroduced_collisions
    else
      stopped_reason ||= :max_iterations
    end

    @last_resolution_result = Gruff::LabelPlacement::ResolutionResult.new(
      labels: labels,
      unresolved_pairs: unresolved_pairs,
      iteration_count: iteration_count,
      stopped_reason: stopped_reason
    )
    @debug_hook.call(@last_resolution_result) if @debug_hook

    labels
  end

private

  # @rbs labels: Array[Gruff::LabelPlacement::PlacedLabel]
  # @rbs return: void
  def prepare(labels)
  end

  # @rbs labels: Array[Gruff::LabelPlacement::PlacedLabel]
  # @rbs return: void
  def tighten(labels)
  end

  # @rbs pairs: Array[[Gruff::LabelPlacement::PlacedLabel, Gruff::LabelPlacement::PlacedLabel]]
  # @rbs collision_counts: Hash[String | Symbol | Integer, Integer]
  # @rbs return: Array[[Gruff::LabelPlacement::PlacedLabel, Gruff::LabelPlacement::PlacedLabel]]
  def sorted_pairs(pairs, collision_counts)
    pairs.sort_by do |first, second|
      pair_sort_key(first, second, collision_counts)
    end
  end

  # @rbs first: Gruff::LabelPlacement::PlacedLabel
  # @rbs second: Gruff::LabelPlacement::PlacedLabel
  # @rbs collision_counts: Hash[String | Symbol | Integer, Integer]
  # @rbs return: Array[Integer]
  def pair_sort_key(first, second, collision_counts)
    first_count = collision_counts[first.id]
    second_count = collision_counts[second.id]
    orders = [first.order, second.order].sort

    [
      -[first_count, second_count].max,
      -[first_count, second_count].min,
      orders[0],
      orders[1]
    ]
  end

  # @rbs first: Gruff::LabelPlacement::PlacedLabel
  # @rbs second: Gruff::LabelPlacement::PlacedLabel
  # @rbs labels: Array[Gruff::LabelPlacement::PlacedLabel]
  # @rbs collision_counts: Hash[String | Symbol | Integer, Integer]
  # @rbs return: bool
  def move_pair(first, second, labels, collision_counts)
    moved_any = false

    candidate_labels_for_pair(first, second, collision_counts).each do |label|
      next unless can_move_label?(label, labels)

      move_label!(label, labels)
      moved_any = true

      break unless @collision_detector.collides?(first, second)
    end

    moved_any
  end

  # @rbs first: Gruff::LabelPlacement::PlacedLabel
  # @rbs second: Gruff::LabelPlacement::PlacedLabel
  # @rbs collision_counts: Hash[String | Symbol | Integer, Integer]
  # @rbs return: Array[Gruff::LabelPlacement::PlacedLabel]
  def candidate_labels_for_pair(first, second, collision_counts)
    preferred_labels = labels_for_pair(first, second, collision_counts)
    remaining_labels = [first, second].reject do |candidate|
      preferred_labels.any? { |label| label.id == candidate.id }
    end

    preferred_labels + remaining_labels
  end

  # @rbs first: Gruff::LabelPlacement::PlacedLabel
  # @rbs second: Gruff::LabelPlacement::PlacedLabel
  # @rbs collision_counts: Hash[String | Symbol | Integer, Integer]
  # @rbs return: Array[Gruff::LabelPlacement::PlacedLabel]
  def labels_for_pair(first, second, collision_counts)
    first_count = collision_counts[first.id]
    second_count = collision_counts[second.id]

    return [first] if first_count > second_count
    return [second] if second_count > first_count

    tie_breaker_labels(first, second)
  end

  # @rbs first: Gruff::LabelPlacement::PlacedLabel
  # @rbs second: Gruff::LabelPlacement::PlacedLabel
  # @rbs return: Array[Gruff::LabelPlacement::PlacedLabel]
  def tie_breaker_labels(first, second)
    raise NotImplementedError, "#{self.class} must implement #tie_breaker_labels"
  end

  # @rbs label: Gruff::LabelPlacement::PlacedLabel
  # @rbs labels: Array[Gruff::LabelPlacement::PlacedLabel]
  # @rbs return: bool
  def can_move_label?(label, labels)
    raise NotImplementedError, "#{self.class} must implement #can_move_label?"
  end

  # @rbs label: Gruff::LabelPlacement::PlacedLabel
  # @rbs labels: Array[Gruff::LabelPlacement::PlacedLabel]
  # @rbs return: void
  def move_label!(label, labels)
    raise NotImplementedError, "#{self.class} must implement #move_label!"
  end
end
