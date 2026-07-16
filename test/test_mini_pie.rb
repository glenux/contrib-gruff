# frozen_string_literal: true
# rbs_inline: enabled

require_relative 'gruff_test_case'

class TestMiniPie < GruffTestCase
  def test_simple_pie
    g = setup_basic_graph(Gruff::Mini::Pie, 200)
    write_test_file(g, 'mini_pie.png')

    assert_same_image('test/expected/mini_pie.png', 'test/output/mini_pie.png')
  end

  def test_pie_with_legend_right
    g = setup_basic_graph(Gruff::Mini::Pie, 200)
    g.legend_position = :right
    write_test_file(g, 'mini_pie_right_legend.png')

    assert_same_image('test/expected/mini_pie_right_legend.png', 'test/output/mini_pie_right_legend.png')
  end

  def test_right_legend_keeps_long_labels_out_of_reserved_legend_area
    g = Gruff::Mini::Pie.new(200)
    g.font = File.join(fixtures_dir, 'Roboto-Light.ttf')
    g.legend_position = :right
    g.sort = false
    g.label_formatting = ->(value, percentage) { "#{value} (#{percentage}%)" }

    10.times do |index|
      g.data("Slice #{index + 1}", 4)
    end
    g.data('Large', 80)

    g.send(:setup_data)
    g.send(:setup_drawing)

    labels = []
    g.send(:slices).each do |slice|
      next unless slice.value > 0

      label = g.send(:process_label_for, slice, labels.length)
      labels << label if label
      g.send(:update_chart_degrees_with, slice.degrees)
    end

    positioned_labels = g.send(:position_labels, labels)
    legend_left_edge = g.send(:right_legend_left_edge)

    assert positioned_labels.any?(&:moved)
    assert positioned_labels.all? { |label| label.right <= legend_left_edge }
  end

  def test_duck_typing
    g = Gruff::Mini::Pie.new(200)
    g.data :A, GruffCustomData.new([25]), '#113285'
    g.data :B, GruffCustomData.new([20]), '#86A697'
    g.data :C, GruffCustomData.new([55]), '#E03C8A'

    g.data :Bob, GruffCustomData.new([50, 19, 31, 89, 20, 54, 37, 65]), '#33A6B8'
    g.write('test/output/mini_pie_duck_typing.png')

    assert_same_image('test/expected/mini_pie_duck_typing.png', 'test/output/mini_pie_duck_typing.png')
  end
end
