# Caja orientada que envuelve la selección: medidas, tiradores y plano divisor.
# Las coordenadas son las proyecciones sobre los tres ejes de la caja, medidas
# desde el origen del modelo.

module GrupoCosmic
  module GCStretch
    class StretchBox
      Handle = Struct.new(:axis, :side, :position)

      attr_reader :frame, :min, :max

      # frame: tres vectores unitarios perpendiculares; points: puntos a envolver.
      def initialize(frame, points)
        @frame = frame
        coords = points.map { |p| (0..2).map { |k| coord(p, k) } }
        @min = (0..2).map { |k| coords.map { |c| c[k] }.min }
        @max = (0..2).map { |k| coords.map { |c| c[k] }.max }
      end

      def coord(pt, k)
        a = @frame[k]
        pt.x * a.x + pt.y * a.y + pt.z * a.z
      end

      def point(c)
        x, y, z = @frame
        Geom::Point3d.new(x.x * c[0] + y.x * c[1] + z.x * c[2],
                          x.y * c[0] + y.y * c[1] + z.y * c[2],
                          x.z * c[0] + y.z * c[1] + z.z * c[2])
      end

      def size(k)
        @max[k] - @min[k]
      end

      def center
        (0..2).map { |k| (@min[k] + @max[k]) / 2.0 }
      end

      def longest_axis
        (0..2).max_by { |k| size(k) }
      end

      def corners(min = @min, max = @max)
        (0..7).map do |i|
          point([(i & 1).zero? ? min[0] : max[0],
                 (i & 2).zero? ? min[1] : max[1],
                 (i & 4).zero? ? min[2] : max[2]])
        end
      end

      # Un tirador en el centro de cada cara, salvo en direcciones sin grosor.
      def handles
        list = []
        3.times do |k|
          next if size(k) < TOL
          [-1, 1].each do |side|
            c = center
            c[k] = side > 0 ? @max[k] : @min[k]
            list << Handle.new(k, side, point(c))
          end
        end
        list
      end

      # Posición del divisor del eje k: la pedida, o el centro si no hay o se sale.
      def divider(k, wanted)
        return center[k] if wanted.nil? || wanted < @min[k] || wanted > @max[k]
        wanted
      end

      def divider_point(k, d)
        c = center
        c[k] = d
        point(c)
      end

      # Rectángulo del divisor, algo mayor que la caja para que se vea.
      def divider_corners(k, d)
        a, b = [0, 1, 2] - [k]
        ma = [size(a) * 0.08, 1.0].max
        mb = [size(b) * 0.08, 1.0].max
        [[-1, -1], [1, -1], [1, 1], [-1, 1]].map do |sa, sb|
          c = [0.0, 0.0, 0.0]
          c[k] = d
          c[a] = sa > 0 ? @max[a] + ma : @min[a] - ma
          c[b] = sb > 0 ? @max[b] + mb : @min[b] - mb
          point(c)
        end
      end

      # Caja resultante de crecer `growth` por el lado del tirador (y lo mismo
      # por el contrario si es simétrico).
      def grown(handle, growth, symmetric)
        mn = @min.dup
        mx = @max.dup
        k = handle.axis
        if handle.side > 0
          mx[k] += growth
          mn[k] -= growth if symmetric
        else
          mn[k] -= growth
          mx[k] += growth if symmetric
        end
        corners(mn, mx)
      end
    end
  end
end
