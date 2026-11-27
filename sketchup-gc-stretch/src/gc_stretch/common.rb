# Ajustes y utilidades compartidas por las dos herramientas.

module GrupoCosmic
  module GCStretch
    IDENTITY = Geom::Transformation.new

    module Settings
      SECTION = 'GrupoCosmic_GCStretch'.freeze

      def self.make_unique?
        Sketchup.read_default(SECTION, 'make_unique', true) ? true : false
      end

      def self.make_unique=(value)
        Sketchup.write_default(SECTION, 'make_unique', value ? true : false)
      end

      def self.toggle_make_unique
        self.make_unique = !make_unique?
      end
    end

    module Util
      # Las 12 aristas de una caja cuyas 8 esquinas se numeran por bits (x, y, z).
      BOX_EDGES = (0..7).flat_map do |i|
        [1, 2, 4].select { |bit| (i & bit).zero? }.map { |bit| [i, i | bit] }
      end.freeze

      COLOR_OK = Sketchup::Color.new(0, 110, 255)
      COLOR_SHARED = Sketchup::Color.new(225, 40, 40)

      def shift(pt, vec)
        Geom::Point3d.new(pt.x + vec.x, pt.y + vec.y, pt.z + vec.z)
      end

      def scaled(vec, factor)
        Geom::Vector3d.new(vec.x * factor, vec.y * factor, vec.z * factor)
      end

      def between(a, b)
        Geom::Vector3d.new(b.x - a.x, b.y - a.y, b.z - a.z)
      end

      def instance?(entity)
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end

      def stretchable(entities)
        entities.select do |e|
          e.valid? && (e.is_a?(Sketchup::Edge) || e.is_a?(Sketchup::Face) ||
                       e.is_a?(Sketchup::Image) || instance?(e))
        end
      end

      # Texto del cuadro de medidas convertido en longitud; nil si no es válido.
      def parse_length(text)
        text.to_s.strip.to_l.to_f
      rescue ArgumentError
        nil
      end

      def box_lines(corners)
        BOX_EDGES.flat_map { |a, b| [corners[a], corners[b]] }
      end

      # Puntos (de dos en dos) de las aristas afectadas, ya desplazadas.
      def preview_lines(preview, vectors)
        lines = []
        preview.segments.each do |pa, ia, pb, ib|
          lines << (ia ? shift(pa, vectors[ia]) : pa)
          lines << (ib ? shift(pb, vectors[ib]) : pb)
        end
        preview.boxes.each do |corners, i|
          lines.concat(box_lines(corners.map { |c| shift(c, vectors[i]) }))
        end
        lines
      end

      def preview_color(preview)
        preview.shared ? COLOR_SHARED : COLOR_OK
      end

      def preview_note(preview)
        return ' No hay nada que estirar ahí.' if preview.empty?
        if preview.shared
          ' ATENCIÓN: se modificarán todas las copias de los componentes afectados.'
        elsif preview.unique_count > 0
          ' Los componentes que se deformen se harán únicos.'
        else
          ''
        end
      end

      # Distancia en píxeles del cursor a un segmento del modelo.
      def screen_distance_to_segment(view, x, y, a, b)
        sa = view.screen_coords(a)
        sb = view.screen_coords(b)
        dx = sb.x - sa.x
        dy = sb.y - sa.y
        len2 = dx * dx + dy * dy
        t = len2 < 1.0e-9 ? 0.0 : ((x - sa.x) * dx + (y - sa.y) * dy) / len2
        t = [[t, 0.0].max, 1.0].min
        Math.hypot(x - (sa.x + dx * t), y - (sa.y + dy * t))
      end

      def run_stretch(model, name)
        model.start_operation(name, true)
        yield
        model.commit_operation
        true
      rescue StandardError => e
        model.abort_operation
        UI.messagebox("GC Stretch no ha podido estirar:\n#{e.message}")
        false
      end
    end
  end
end
