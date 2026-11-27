# Regiones del espacio (en coordenadas del modelo) que deciden qué vértices
# se mueven en un estirado. Todas responden a:
#   contains?(pt)        el punto está dentro
#   contains_all?(pts)   todos los puntos están dentro (objeto entero dentro)
#   excludes_all?(pts)   seguro que nada del volumen convexo de pts está dentro
# Solo se usan x, y, z de los puntos, para poder probarlas fuera de SketchUp.

module GrupoCosmic
  module GCStretch
    TOL = 0.001 # pulgadas: la tolerancia propia de SketchUp

    module Regions
      def self.dot(pt, origin, normal)
        (pt.x - origin.x) * normal.x + (pt.y - origin.y) * normal.y +
          (pt.z - origin.z) * normal.z
      end

      # Todo lo que queda a un lado de un plano (el lado al que apunta la normal).
      # Lo que está justo sobre el plano no se mueve.
      class HalfSpace
        def initialize(point, normal)
          @point = point
          @normal = normal
        end

        def contains?(pt)
          Regions.dot(pt, @point, @normal) > TOL
        end

        # Un objeto apoyado en el plano y con el resto en el lado que se mueve
        # cuenta como entero dentro: se desplaza sin deformarse.
        def contains_all?(pts)
          some = false
          pts.each do |pt|
            d = Regions.dot(pt, @point, @normal)
            return false if d < -TOL
            some = true if d > TOL
          end
          some
        end

        def excludes_all?(pts)
          pts.none? { |pt| contains?(pt) }
        end
      end

      # Celda entre varios planos divisores (uno por eje que se estira a la vez).
      # Cada plano pide un lado: :pos (el del tirador), :neg (el contrario),
      # :mid (justo sobre el plano) o :notpos (cualquiera salvo el del tirador).
      class Cell
        # constraints: lista de [punto, normal, lado]
        def initialize(constraints)
          @constraints = constraints
        end

        def contains?(pt)
          @constraints.all? do |point, normal, state|
            d = Regions.dot(pt, point, normal)
            case state
            when :pos then d > TOL
            when :neg then d < -TOL
            when :mid then d.abs <= TOL
            else d <= TOL
            end
          end
        end

        # Como en HalfSpace: lo que se apoya en un plano cuenta como entero en
        # el lado en el que tiene el resto.
        def contains_all?(pts)
          @constraints.all? do |point, normal, state|
            ds = pts.map { |pt| Regions.dot(pt, point, normal) }
            case state
            when :pos then ds.all? { |d| d >= -TOL } && ds.any? { |d| d > TOL }
            when :neg then ds.all? { |d| d <= TOL } && ds.any? { |d| d < -TOL }
            when :mid then ds.all? { |d| d.abs <= TOL }
            else ds.all? { |d| d <= TOL }
            end
          end
        end

        def excludes_all?(pts)
          @constraints.any? do |point, normal, state|
            ds = pts.map { |pt| Regions.dot(pt, point, normal) }
            case state
            when :pos then ds.none? { |d| d > TOL }
            when :neg then ds.none? { |d| d < -TOL }
            when :mid then ds.all? { |d| d > TOL } || ds.all? { |d| d < -TOL }
            else ds.all? { |d| d > TOL }
            end
          end
        end
      end

      # Ventana dibujada en pantalla, convertida en una pirámide (o prisma, en
      # proyección paralela) de cuatro planos que se aleja de la cámara.
      class Frustum
        RAY_LENGTH = 1000.0
        RayPoint = Struct.new(:x, :y, :z)

        # rays: los cuatro rayos de las esquinas, en orden alrededor de la
        # ventana; center: el rayo del centro. Cada rayo es [punto, vector].
        def self.from_rays(rays, center)
          ref = along(center)
          planes = []
          rays.each_with_index do |ray, i|
            a = ray[0]
            b = along(ray)
            c = along(rays[(i + 1) % rays.size])
            u = [b.x - a.x, b.y - a.y, b.z - a.z]
            v = [c.x - a.x, c.y - a.y, c.z - a.z]
            n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2],
                 u[0] * v[1] - u[1] * v[0]]
            len = Math.sqrt(n[0]**2 + n[1]**2 + n[2]**2)
            return nil if len < 1.0e-9
            n = n.map { |x| x / len }
            side = (ref.x - a.x) * n[0] + (ref.y - a.y) * n[1] + (ref.z - a.z) * n[2]
            return nil if side.abs < 1.0e-9
            n = n.map { |x| -x } if side < 0
            planes << [[a.x.to_f, a.y.to_f, a.z.to_f], n]
          end
          new(planes)
        end

        def self.along(ray)
          p, d = ray
          len = Math.sqrt(d.x**2 + d.y**2 + d.z**2)
          f = RAY_LENGTH / len
          RayPoint.new(p.x + d.x * f, p.y + d.y * f, p.z + d.z * f)
        end

        def initialize(planes)
          @planes = planes
        end

        def contains?(pt)
          @planes.all? { |o, n| side(pt, o, n) >= 0 }
        end

        def contains_all?(pts)
          pts.all? { |pt| contains?(pt) }
        end

        def excludes_all?(pts)
          @planes.any? { |o, n| pts.all? { |pt| side(pt, o, n) < 0 } }
        end

        private

        def side(pt, o, n)
          (pt.x - o[0]) * n[0] + (pt.y - o[1]) * n[1] + (pt.z - o[2]) * n[2]
        end
      end

      # Puntos sueltos (los vértices de la arista o la cara en la que se hizo
      # clic). Arrastra también lo que coincida exactamente con ellos.
      class PointSet
        POINT_TOL = 0.002

        def initialize(points)
          @points = points.map { |p| [p.x.to_f, p.y.to_f, p.z.to_f] }
          @min = (0..2).map { |i| @points.map { |p| p[i] }.min - POINT_TOL }
          @max = (0..2).map { |i| @points.map { |p| p[i] }.max + POINT_TOL }
        end

        def contains?(pt)
          c = [pt.x, pt.y, pt.z]
          return false if (0..2).any? { |i| c[i] < @min[i] || c[i] > @max[i] }
          @points.any? do |p|
            (p[0] - c[0]).abs < POINT_TOL && (p[1] - c[1]).abs < POINT_TOL &&
              (p[2] - c[2]).abs < POINT_TOL
          end
        end

        def contains_all?(pts)
          pts.all? { |pt| contains?(pt) }
        end

        def excludes_all?(pts)
          cs = pts.map { |pt| [pt.x, pt.y, pt.z] }
          (0..2).any? do |i|
            cs.all? { |c| c[i] < @min[i] } || cs.all? { |c| c[i] > @max[i] }
          end
        end
      end

      # Suma y resta de regiones, en el orden en que el usuario las fue creando.
      class Composite
        def initialize
          @ops = []
        end

        def add(region)
          @ops << [:add, region]
          self
        end

        def subtract(region)
          @ops << [:subtract, region]
          self
        end

        def empty?
          @ops.none? { |op, _| op == :add }
        end

        def contains?(pt)
          inside = false
          @ops.each do |op, region|
            if op == :add
              inside ||= region.contains?(pt)
            elsif inside
              inside = !region.contains?(pt)
            end
          end
          inside
        end

        def contains_all?(pts)
          pts.all? { |pt| contains?(pt) }
        end

        def excludes_all?(pts)
          @ops.all? { |op, region| op != :add || region.excludes_all?(pts) }
        end
      end
    end
  end
end
