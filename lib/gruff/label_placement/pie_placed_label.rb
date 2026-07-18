# frozen_string_literal: true

# rbs_inline: enabled

# @private
class Gruff::LabelPlacement::PiePlacedLabel < Gruff::LabelPlacement::PlacedLabel
  attr_reader :angle #: Float
  attr_reader :base_x #: Float
  attr_reader :base_y #: Float
  attr_reader :color #: String
  attr_reader :side #: Symbol
  attr_reader :slice_degrees #: Float
  attr_reader :slice_value #: Float | Integer

  # @rbs id: String | Symbol | Integer
  # @rbs text: String
  # @rbs x: Float | Integer
  # @rbs y: Float | Integer
  # @rbs width: Float | Integer
  # @rbs height: Float | Integer
  # @rbs order: Integer
  # @rbs angle: Float | Integer
  # @rbs base_x: Float | Integer
  # @rbs base_y: Float | Integer
  # @rbs color: String
  # @rbs side: Symbol
  # @rbs slice_degrees: Float | Integer
  # @rbs slice_value: Float | Integer
  # @rbs return: void
  def initialize(id:, text:, x:, y:, width:, height:, order:, angle:, base_x:, base_y:, color:, side:, slice_degrees:, slice_value:)
    super(id: id, text: text, x: x, y: y, width: width, height: height, order: order)
    @angle = angle.to_f
    @base_x = base_x.to_f
    @base_y = base_y.to_f
    @color = color
    @side = side
    @slice_degrees = slice_degrees.to_f
    @slice_value = slice_value
  end

  # @rbs return: Float
  def anchor_x
    side == :right ? left : right
  end

  # @rbs return: Float
  def anchor_y
    y
  end
end
