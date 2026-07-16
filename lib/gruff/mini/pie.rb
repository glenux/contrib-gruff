# frozen_string_literal: true
# rbs_inline: enabled

#
# Makes a small pie graph suitable for display at 200px or even smaller.
#
# Here's how to set up a Gruff::Mini::Pie.
#
#   g = Gruff::Mini::Pie.new
#   g.title = "Visual Pie Graph Test"
#   g.data 'Fries', 20
#   g.data 'Hamburgers', 50
#   g.write("mini_pie_keynote.png")
#
class Gruff::Mini::Pie < Gruff::Pie
private

  include Gruff::Mini::Legend

  # @rbs return: void
  def initialize_attributes
    super

    @hide_legend = true
    @hide_title = true
    @hide_line_numbers = true

    @marker_font.size = 50.0
    @legend_font.size = 50.0
  end

  # @rbs return: void
  def setup_data
    expand_canvas_for_vertical_legend # steep:ignore
    super
  end

  # @rbs return: void
  def draw_graph
    super
    draw_vertical_legend # steep:ignore
  end

  # Keep repositioned labels out of the reserved right legend area.
  # @rbs return: Float | Integer
  def label_placement_max_x
    return super unless right_legend_reserved?

    right_legend_left_edge
  end

  # @rbs return: bool
  def right_legend_reserved?
    @legend_position == :right && !@hide_mini_legend && !@original_columns.nil?
  end

  # @rbs return: Float | Integer
  def right_legend_left_edge
    @original_columns + @left_margin
  end
end
