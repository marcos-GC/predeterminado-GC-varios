# Doble mínimo de la API de SketchUp para probar el motor fuera del programa.
# Solo imita lo que usa el motor: puntos, vectores, transformaciones, aristas,
# grupos, componentes y definiciones.

module Geom
  class Vector3d
    attr_reader :x, :y, :z
    def initialize(x = 0, y = 0, z = 0)
      @x, @y, @z = x.to_f, y.to_f, z.to_f
    end

    def length
      Math.sqrt(x * x + y * y + z * z)
    end

    def transform(tr)
      m = tr.m
      Vector3d.new(m[0] * x + m[1] * y + m[2] * z,
                   m[4] * x + m[5] * y + m[6] * z,
                   m[8] * x + m[9] * y + m[10] * z)
    end
  end

  class Point3d
    attr_reader :x, :y, :z
    def initialize(x = 0, y = 0, z = 0)
      @x, @y, @z = x.to_f, y.to_f, z.to_f
    end

    def transform(tr)
      m = tr.m
      Point3d.new(m[0] * x + m[1] * y + m[2] * z + m[3],
                  m[4] * x + m[5] * y + m[6] * z + m[7],
                  m[8] * x + m[9] * y + m[10] * z + m[11])
    end

    def to_a
      [x, y, z]
    end
  end

  # Matriz 4x4 por filas; la traslación va en la última columna.
  class Transformation
    attr_reader :m
    def initialize(m = nil)
      @m = m || [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1].map(&:to_f)
    end

    def self.translation(v)
      new([1, 0, 0, v.x, 0, 1, 0, v.y, 0, 0, 1, v.z, 0, 0, 0, 1].map(&:to_f))
    end

    def self.scaling(sx, sy, sz)
      new([sx, 0, 0, 0, 0, sy, 0, 0, 0, 0, sz, 0, 0, 0, 0, 1].map(&:to_f))
    end

    def self.rotation_z(angle)
      c = Math.cos(angle)
      s = Math.sin(angle)
      new([c, -s, 0, 0, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1].map(&:to_f))
    end

    def *(other)
      r = Array.new(16, 0.0)
      4.times do |i|
        4.times do |j|
          4.times { |k| r[i * 4 + j] += @m[i * 4 + k] * other.m[k * 4 + j] }
        end
      end
      Transformation.new(r)
    end

    def origin
      Point3d.new(@m[3], @m[7], @m[11])
    end

    def inverse
      a = (0..3).map { |i| @m[i * 4, 4] + (0..3).map { |j| i == j ? 1.0 : 0.0 } }
      4.times do |c|
        p = (c..3).max_by { |r| a[r][c].abs }
        a[c], a[p] = a[p], a[c]
        d = a[c][c]
        a[c] = a[c].map { |x| x / d }
        4.times do |r|
          next if r == c
          f = a[r][c]
          a[r] = a[r].each_with_index.map { |x, k| x - f * a[c][k] }
        end
      end
      Transformation.new(a.flat_map { |row| row[4, 4] })
    end
  end

  class BoundingBox
    def initialize
      @pts = []
    end

    def add(pt)
      @pts << pt
      self
    end

    def min
      Point3d.new(*(0..2).map { |i| @pts.map { |p| p.to_a[i] }.min })
    end

    def max
      Point3d.new(*(0..2).map { |i| @pts.map { |p| p.to_a[i] }.max })
    end
  end
end

module Sketchup
  class Entity
    def valid?
      true
    end
  end

  class Vertex < Entity
    attr_accessor :position
    def initialize(pt)
      @position = pt
    end
  end

  class Edge < Entity
    attr_reader :vertices
    def initialize(a, b)
      @vertices = [a, b]
    end
  end

  class Face < Entity
    attr_reader :edges
    def initialize(edges)
      @edges = edges
    end
  end

  class Image < Entity; end

  class Entities
    include Enumerable
    attr_reader :list
    def initialize
      @list = []
    end

    def each(&block)
      @list.each(&block)
    end

    def length
      @list.length
    end

    def <<(entity)
      @list << entity
      self
    end

    def transform_by_vectors(vertices, vectors)
      raise 'tamaños distintos' unless vertices.size == vectors.size
      vertices.each_with_index do |v, i|
        raise 'vértice ajeno' unless @list.any? { |e| e.is_a?(Edge) && e.vertices.include?(v) }
        d = vectors[i]
        p = v.position
        v.position = Geom::Point3d.new(p.x + d.x, p.y + d.y, p.z + d.z)
      end
    end

    # Caja de dx × dy × dz con una esquina en (x, y, z): 8 vértices, 12 aristas.
    def add_box(x, y, z, dx, dy, dz)
      vs = (0..7).map do |i|
        Vertex.new(Geom::Point3d.new(x + ((i & 1).zero? ? 0 : dx),
                                     y + ((i & 2).zero? ? 0 : dy),
                                     z + ((i & 4).zero? ? 0 : dz)))
      end
      edges = []
      8.times do |i|
        [1, 2, 4].each { |bit| edges << Edge.new(vs[i], vs[i | bit]) if (i & bit).zero? }
      end
      @list.concat(edges)
      edges
    end
  end

  class ComponentDefinition
    attr_reader :entities, :instances
    def initialize
      @entities = Entities.new
      @instances = []
    end

    def bounds
      bb = Geom::BoundingBox.new
      @entities.each do |e|
        case e
        when Edge
          e.vertices.each { |v| bb.add(v.position) }
        when Group, ComponentInstance
          b = e.definition.bounds
          mn = b.min
          mx = b.max
          8.times do |i|
            bb.add(Geom::Point3d.new((i & 1).zero? ? mn.x : mx.x,
                                     (i & 2).zero? ? mn.y : mx.y,
                                     (i & 4).zero? ? mn.z : mx.z).transform(e.transformation))
          end
        end
      end
      bb
    end

    # Copia propia de la geometría; los hijos siguen compartiendo definición.
    def duplicate
      copy = ComponentDefinition.new
      map = {}
      @entities.each do |e|
        case e
        when Edge
          a, b = e.vertices.map { |v| map[v] ||= Vertex.new(v.position) }
          copy.entities << Edge.new(a, b)
        when Group, ComponentInstance
          copy.entities << e.class.new(e.definition, e.transformation)
        end
      end
      copy
    end
  end

  class ComponentInstance < Entity
    attr_reader :definition, :transformation
    attr_accessor :locked
    def initialize(definition, transformation = Geom::Transformation.new)
      @definition = definition
      @transformation = transformation
      definition.instances << self
    end

    def locked?
      @locked ? true : false
    end

    def transform!(tr)
      @transformation = tr * @transformation
    end

    def make_unique
      return self if @definition.instances.length < 2
      @definition.instances.delete(self)
      @definition = @definition.duplicate
      @definition.instances << self
      self
    end
  end

  class Group < ComponentInstance; end
end
