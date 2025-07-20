# Simplified version of RQRCode::QRCode.new(...).as_svg.
class Qrcode
  def initialize(...)
    @qrcode = RQRCodeCore::QRCode.new(...)
  end

  def to_svg(**svg_attrs)
    size      = @qrcode.module_count + 10
    svg_attrs = svg_attrs.merge(
      version:             "1.1",
      xmlns:               "http://www.w3.org/2000/svg",
      "shape-rendering" => "crispEdges",
      viewBox:             "0 0 #{size} #{size}",
    ).map { |k, v| %(#{k}="#{v}") }.join(" ")

    %(<svg #{svg_attrs}><rect width="#{size}" height="#{size}" fill="#fff"/>#{to_path}</svg>)
  end

  SVG_PATH_COMMANDS = {
    move:  "M",
    up:    "v-",
    down:  "v",
    left:  "h-",
    right: "h",
    close: "z",
  }.freeze
  private_constant :SVG_PATH_COMMANDS

  Edge = Struct.new(:start_x, :start_y, :direction) do
    def end_x
      case direction
      when :right then start_x + 1
      when :left  then start_x - 1
      else start_x
      end
    end

    def end_y
      case direction
      when :down then start_y + 1
      when :up   then start_y - 1
      else start_y
      end
    end
  end
  private_constant :Edge

  def to_path # rubocop:disable Metrics
    modules_array = @qrcode.modules
    matrix_width  = matrix_height = modules_array.length + 1
    empty_row     = [Array.new(matrix_width - 1, false)]
    edge_matrix   = Array.new(matrix_height) { Array.new(matrix_width) }

    (empty_row + modules_array + empty_row).each_cons(2).with_index do |(first_row, second_row), row_idx|
      # horizontal edges
      first_row.zip(second_row).each_with_index do |cell_pair, col_idx|
        edge = case cell_pair
        when [true, false] then Edge.new col_idx + 1, row_idx, :left
        when [false, true] then Edge.new col_idx, row_idx, :right
        end

        (edge_matrix[edge.start_y][edge.start_x] ||= []) << edge if edge
      end

      # vertical edges
      ([false] + second_row + [false]).each_cons(2).each_with_index do |cell_pair, col_idx|
        edge = case cell_pair
        when [true, false] then Edge.new col_idx, row_idx, :down
        when [false, true] then Edge.new col_idx, row_idx + 1, :up
        end

        (edge_matrix[edge.start_y][edge.start_x] ||= []) << edge if edge
      end
    end

    edge_count = edge_matrix.flatten.compact.count
    path       = []

    while edge_count > 0
      edge_loop        = []
      next_matrix_cell = edge_matrix.find(&:any?).find { _1&.any? }
      edge             = next_matrix_cell.first

      while edge
        edge_loop  << edge
        matrix_cell = edge_matrix[edge.start_y][edge.start_x]
        matrix_cell.delete edge

        edge_matrix[edge.start_y][edge.start_x] = nil if matrix_cell.empty?

        edge_count -= 1

        # try to find an edge continuing the current edge
        edge = edge_matrix[edge.end_y][edge.end_x]&.first
      end

      first_edge        = edge_loop.first
      edge_loop_string  = SVG_PATH_COMMANDS[:move]
      edge_loop_string += "#{first_edge.start_x} #{first_edge.start_y}"

      edge_loop.chunk(&:direction).to_a[0...-1].each do |direction, edges|
        edge_loop_string << "#{SVG_PATH_COMMANDS[direction]}#{edges.length}"
      end

      edge_loop_string << SVG_PATH_COMMANDS[:close]
      path             << edge_loop_string
    end

    %(<path d="#{path.join}" fill="#000" transform="translate(5,5)"/>)
  end
end
