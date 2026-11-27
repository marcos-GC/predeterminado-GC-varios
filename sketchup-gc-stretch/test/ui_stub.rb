# Ampliación del doble de SketchUp para mover las herramientas sin el programa:
# una vista de frente en proyección paralela (pantalla x = X, pantalla y = -Z).
require_relative 'sketchup_stub'

%w[VK_UP VK_DOWN VK_LEFT VK_RIGHT].each_with_index { |n, i| Object.const_set(n, 37 + i) }
COPY_MODIFIER_KEY = 17
COPY_MODIFIER_MASK = 8
CONSTRAIN_MODIFIER_MASK = 4
MF_CHECKED = 8
MF_UNCHECKED = 0
GL_LINES = 1
GL_LINE_LOOP = 2
GL_QUADS = 7

class String
  def to_l
    Float(self)
  rescue ArgumentError
    raise ArgumentError, 'longitud no válida'
  end
end

class Float
  def to_l
    self
  end
end

module Geom
  class Vector3d
    def dot(o)
      x * o.x + y * o.y + z * o.z
    end

    def normalize
      l = length
      Vector3d.new(x / l, y / l, z / l)
    end
  end

  class Point3d
    def project_to_line(line)
      p, d = line
      t = ((x - p.x) * d.x + (y - p.y) * d.y + (z - p.z) * d.z) / d.dot(d)
      Point3d.new(p.x + d.x * t, p.y + d.y * t, p.z + d.z * t)
    end
  end

  class Transformation
    def xaxis
      Vector3d.new(@m[0], @m[4], @m[8])
    end

    def yaxis
      Vector3d.new(@m[1], @m[5], @m[9])
    end

    def zaxis
      Vector3d.new(@m[2], @m[6], @m[10])
    end
  end

  class BoundingBox
    def empty?
      @pts.empty?
    end

    def corner(i)
      mn = min
      mx = max
      Point3d.new((i & 1).zero? ? mn.x : mx.x, (i & 2).zero? ? mn.y : mx.y,
                  (i & 4).zero? ? mn.z : mx.z)
    end
  end

  def self.intersect_line_plane(line, plane)
    p, d = line
    o, n = plane
    den = d.dot(n)
    return nil if den.abs < 1.0e-12
    t = ((o.x - p.x) * n.x + (o.y - p.y) * n.y + (o.z - p.z) * n.z) / den
    Point3d.new(p.x + d.x * t, p.y + d.y * t, p.z + d.z * t)
  end

  def self.closest_points(l1, l2)
    p1, d1 = l1
    p2, d2 = l2
    w = Vector3d.new(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z)
    a = d1.dot(d1)
    b = d1.dot(d2)
    c = d2.dot(d2)
    d = d1.dot(w)
    e = d2.dot(w)
    den = a * c - b * b
    s = (b * e - c * d) / den
    t = (a * e - b * d) / den
    [Point3d.new(p1.x + d1.x * s, p1.y + d1.y * s, p1.z + d1.z * s),
     Point3d.new(p2.x + d2.x * t, p2.y + d2.y * t, p2.z + d2.z * t)]
  end
end

X_AXIS = Geom::Vector3d.new(1, 0, 0)
Y_AXIS = Geom::Vector3d.new(0, 1, 0)
Z_AXIS = Geom::Vector3d.new(0, 0, 1)

module UI
  def self.beep; end

  def self.messagebox(text)
    raise text
  end

  def self.start_timer(*)
    yield
  end

  class << self
    attr_accessor :answers
  end

  def self.inputbox(prompts, _defaults, _title)
    raise 'número de campos' unless prompts.size == answers.size
    answers
  end
end

module Sketchup
  class Color
    def initialize(*); end
  end

  class InputPoint
    attr_reader :position
    def pick(_view, x, y, _other = nil)
      @position = Geom::Point3d.new(x, 0, -y)
    end

    def valid?
      !@position.nil?
    end

    def degrees_of_freedom
      3
    end

    def tooltip
      ''
    end

    def draw(_view); end
  end

  class PickHelper
    attr_accessor :best_picked
    def do_pick(*); end

    def count
      0
    end
  end

  class View
    attr_reader :drawn
    attr_accessor :tooltip, :line_width, :line_stipple, :drawing_color
    def initialize
      @drawn = 0
      @helper = PickHelper.new
    end

    def pick_helper
      @helper
    end

    def camera
      Struct.new(:direction).new(Geom::Vector3d.new(0, 1, 0))
    end

    def invalidate; end

    def screen_coords(p)
      Geom::Point3d.new(p.x, -p.z, 0)
    end

    def pickray(x, y)
      [Geom::Point3d.new(x, -5000, -y), Geom::Vector3d.new(0, 1, 0)]
    end

    def draw(_mode, points)
      raise 'nada que dibujar' if points.empty?
      @drawn += 1
    end
    alias draw2d draw

    def draw_points(points, *)
      raise 'nada que dibujar' if points.empty?
      @drawn += 1
    end
  end

  class Selection
    include Enumerable
    def initialize
      @list = []
    end

    def each(&block)
      @list.each(&block)
    end

    def add(e)
      @list << e
    end

    def clear
      @list.clear
    end

    def toggle(e)
      @list.include?(e) ? @list.delete(e) : @list << e
    end
  end

  class Model
    attr_reader :selection, :active_entities, :active_view, :operations
    def initialize
      @selection = Selection.new
      @active_entities = Entities.new
      @active_view = View.new
      @operations = []
    end

    def active_path
      nil
    end

    def start_operation(name, *)
      @operations << name
    end

    def commit_operation; end

    def abort_operation
      raise 'operación abortada'
    end
  end

  class << self
    attr_accessor :active_model, :status_text, :vcb_label, :vcb_value
    def platform
      :platform_win
    end

    def read_default(_section, key, default)
      (@defaults ||= {}).fetch(key, default)
    end

    def write_default(_section, key, value)
      (@defaults ||= {})[key] = value
    end
  end
end
