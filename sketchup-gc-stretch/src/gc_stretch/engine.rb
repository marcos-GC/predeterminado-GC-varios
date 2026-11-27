# Motor común de las dos herramientas.
#
# Estirar = trasladar un subconjunto de vértices. El motor recorre la jerarquía
# de grupos y componentes de arriba abajo y, en cada nivel:
#   - mueve los vértices sueltos que caen en una región;
#   - un grupo o componente ENTERO dentro de una región se desplaza tal cual,
#     sin tocar su interior (por eso no se deforma);
#   - uno que queda a caballo se abre y se repite el proceso dentro de él,
#     haciéndolo único antes si tiene copias;
#   - uno que queda fuera no se toca.
# Cada región lleva su propio vector de desplazamiento (el estirado simétrico
# usa dos regiones con vectores opuestos).

module GrupoCosmic
  module GCStretch
    class Engine
      MAX_SEGMENTS = 15_000

      Preview = Struct.new(:segments, :boxes, :shared, :truncated,
                           :vertex_count, :instance_count, :unique_count) do
        def empty?
          vertex_count.zero? && instance_count.zero?
        end
      end

      def initialize(regions, make_unique)
        @regions = regions
        @make_unique = make_unique
      end

      # Calcula qué se movería, sin tocar el modelo.
      # segments: [punto_a, región_a, punto_b, región_b] de cada arista afectada.
      # boxes: [8 esquinas, región] de cada objeto que se desplaza entero.
      def preview(items, container, tr)
        @apply = false
        @vectors = nil
        run(items, container, tr)
      end

      # Ejecuta el estirado. vectors: un vector (en coordenadas del modelo) por
      # región. Debe llamarse dentro de una operación de SketchUp.
      def apply(items, container, tr, vectors)
        @apply = true
        @vectors = vectors
        run(items, container, tr)
      end

      private

      def run(items, container, tr)
        @result = Preview.new([], [], false, false, 0, 0, 0)
        @done_definitions = {}
        walk(items, container, tr, false)
        @result
      end

      def walk(items, container, tr, whole_container)
        edges = {}
        instances = []
        images = []
        items.each do |e|
          next unless e.valid?
          case e
          when Sketchup::Edge
            edges[e] = true
          when Sketchup::Face
            e.edges.each { |x| edges[x] = true } unless whole_container
          when Sketchup::Group, Sketchup::ComponentInstance
            instances << e
          when Sketchup::Image
            images << e
          end
        end

        # Vértices sueltos de este nivel.
        world = {}
        region_of = {}
        edges.each_key do |edge|
          edge.vertices.each do |v|
            next if world.key?(v)
            p = v.position.transform(tr)
            world[v] = p
            i = @regions.index { |r| r.contains?(p) }
            region_of[v] = i if i
          end
        end
        @result.vertex_count += region_of.size

        unless @apply
          edges.each_key do |edge|
            a, b = edge.vertices
            ia = region_of[a]
            ib = region_of[b]
            next unless ia || ib
            if @result.segments.size >= MAX_SEGMENTS
              @result.truncated = true
              break
            end
            @result.segments << [world[a], ia, world[b], ib]
          end
        end

        # Qué hacer con cada grupo o componente de este nivel.
        to_move = []
        to_open = []
        instances.each do |inst|
          next if inst.locked?
          definition = inst.definition
          next if definition.entities.length.zero?
          itr = tr * inst.transformation
          corners = box_corners(definition.bounds, itr)
          i = @regions.index { |r| r.contains_all?(corners) }
          if i
            to_move << [inst, i, corners]
          elsif !@regions.all? { |r| r.excludes_all?(corners) }
            to_open << [inst, itr]
          end
        end
        images.each do |image|
          corners = box_corners(image.bounds, tr)
          i = @regions.index { |r| r.contains_all?(corners) }
          to_move << [image, i, corners] if i
        end
        @result.instance_count += to_move.size

        if @apply
          inverse = tr.inverse
          local = @vectors.map { |v| v.transform(inverse) }
          # Destino de cada objeto entero, anotado antes de mover vértices: si
          # está pegado a una cara que también se mueve, SketchUp ya lo arrastra
          # y después solo se corrige la diferencia.
          targets = to_move.map do |inst, i, _|
            shift(inst.transformation.origin, local[i])
          end
          unless region_of.empty?
            vertices = region_of.keys
            container.transform_by_vectors(vertices,
                                           vertices.map { |v| local[region_of[v]] })
          end
          to_move.each_with_index do |(inst, _, _), n|
            next unless inst.valid?
            o = inst.transformation.origin
            t = targets[n]
            rest = Geom::Vector3d.new(t.x - o.x, t.y - o.y, t.z - o.z)
            next if rest.length < TOL / 10
            inst.transform!(Geom::Transformation.translation(rest))
          end
        else
          to_move.each { |_, i, corners| @result.boxes << [corners, i] }
        end

        to_open.each do |inst, itr|
          definition = inst.definition
          if definition.instances.length > 1
            # Un grupo copiado se comporta siempre como único, igual que al
            # editarlo a mano; un componente, según el ajuste del usuario.
            if inst.is_a?(Sketchup::Group) || @make_unique
              @result.unique_count += 1
              if @apply
                inst.make_unique
                definition = inst.definition
              end
            else
              @result.shared = true
              next if @done_definitions[definition]
              @done_definitions[definition] = true
            end
          end
          walk(definition.entities, definition.entities, itr, true)
        end
      end

      def box_corners(bounds, tr)
        mn = bounds.min
        mx = bounds.max
        (0..7).map do |i|
          Geom::Point3d.new((i & 1).zero? ? mn.x : mx.x,
                            (i & 2).zero? ? mn.y : mx.y,
                            (i & 4).zero? ? mn.z : mx.z).transform(tr)
        end
      end

      def shift(pt, vec)
        Geom::Point3d.new(pt.x + vec.x, pt.y + vec.y, pt.z + vec.z)
      end
    end
  end
end
