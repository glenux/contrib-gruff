# frozen_string_literal: true

# rbs_inline: enabled

# @private
class Gruff::LabelPlacement::PlacedLabel
  attr_accessor :id #: String | Symbol | Integer
  attr_accessor :text #: String
  attr_accessor :x #: Float
  attr_accessor :y #: Float
  attr_accessor :width #: Float
  attr_accessor :height #: Float
  attr_accessor :offset #: Float
  attr_accessor :moved #: bool
  attr_reader :order #: Integer

  # @rbs id: String | Symbol | Integer
  # @rbs text: String
  # @rbs x: Float | Integer
  # @rbs y: Float | Integer
  # @rbs width: Float | Integer
  # @rbs height: Float | Integer
  # @rbs order: Integer
  # @rbs return: void
  def initialize(id:, text:, x:, y:, width:, height:, order: 0)
    @id = id
    @text = text
    @x = x.to_f
    @y = y.to_f
    @width = width.to_f
    @height = height.to_f
    @offset = 0.0
    @moved = false
    @order = order
  end

  # @rbs return: Float
  def left
    x - (width / 2.0)
  end

  # @rbs return: Float
  def top
    y - (height / 2.0)
  end

  # @rbs return: Float
  def right
    x + (width / 2.0)
  end

  # @rbs return: Float
  def bottom
    y + (height / 2.0)
  end
end
