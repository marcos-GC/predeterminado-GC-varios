# Pruebas del motor de estirado, fuera de SketchUp:  ruby test/test_engine.rb
require 'minitest/autorun'
require_relative 'sketchup_stub'
require_relative '../src/gc_stretch/regions'
require_relative '../src/gc_stretch/engine'

class EngineTest < Minitest::Test
  include GrupoCosmic::GCStretch

  P = Geom::Point3d
  V = Geom::Vector3d
  T = Geom::Transformation
  ID = T.new

  # Extremos, en coordenadas del modelo, de todo lo que cuelga de `entities`.
  def extents(entities, tr = ID)
    pts = world_points(entities, tr)
    (0..2).map { |i| [pts.map { |p| p[i] }.min.round(6), pts.map { |p| p[i] }.max.round(6)] }
  end

  def world_points(entities, tr)
    pts = []
    entities.each do |e|
      case e
      when Sketchup::Edge
        e.vertices.each { |v| pts << v.position.transform(tr).to_a }
      when Sketchup::ComponentInstance
        pts.concat(world_points(e.definition.entities, tr * e.transformation))
      end
    end
    pts
  end

  def half(x, dir = 1)
    Regions::HalfSpace.new(P.new(x, 0, 0), V.new(dir, 0, 0))
  end

  def stretch(root, regions, vectors, unique = true)
    Engine.new(regions, unique).apply(root.to_a, root, ID, vectors)
  end

  def test_geometria_suelta_solo_mueve_un_lado
    root = Sketchup::Entities.new
    root.add_box(0, 0, 0, 10, 4, 3)
    stretch(root, [half(5)], [V.new(3, 0, 0)])
    assert_equal [[0.0, 13.0], [0.0, 4.0], [0.0, 3.0]], extents(root)
  end

  def test_vertice_sobre_el_plano_no_se_mueve
    root = Sketchup::Entities.new
    root.add_box(0, 0, 0, 5, 4, 3)
    stretch(root, [half(5)], [V.new(3, 0, 0)])
    assert_equal [0.0, 5.0], extents(root)[0]
  end

  # Mueble: tablero largo con una pata a cada lado y un montante en el centro.
  def furniture
    root = Sketchup::Entities.new
    cabinet = Sketchup::ComponentDefinition.new
    cabinet.entities.add_box(0, 0, 10, 100, 20, 2)
    leg = Sketchup::ComponentDefinition.new
    leg.entities.add_box(0, 0, 0, 4, 4, 10)
    legs = [2, 48, 94].map do |x|
      i = Sketchup::ComponentInstance.new(leg, T.translation(V.new(x, 0, 0)))
      cabinet.entities << i
      i
    end
    group = Sketchup::Group.new(cabinet, T.translation(V.new(1000, 0, 0)))
    root << group
    [root, group, legs, leg]
  end

  def test_los_hijos_enteros_se_desplazan_sin_deformarse
    root, group, legs, leg = furniture
    # Divisor en x=1030 (entre la pata izquierda y el montante central).
    stretch(root, [half(1030)], [V.new(50, 0, 0)])
    assert_equal [1000.0, 1150.0], extents(root)[0]
    xs = legs.map { |l| l.transformation.origin.x }
    assert_equal [2.0, 98.0, 144.0], xs
    assert_equal 1, [leg].uniq.size
    assert_equal 3, leg.instances.length, 'las patas siguen siendo el mismo componente'
    assert_equal [[0.0, 4.0], [0.0, 4.0], [0.0, 10.0]], extents(leg.entities)
    assert_same group.definition, root.first.definition
  end

  def test_hijo_a_caballo_se_estira_y_se_hace_unico
    root, _group, legs, leg = furniture
    # El divisor corta el montante central (x local 48..52).
    stretch(root, [half(1050)], [V.new(10, 0, 0)])
    refute_same leg, legs[1].definition
    assert_equal [0.0, 14.0], extents(legs[1].definition.entities)[0]
    assert_equal [0.0, 4.0], extents(leg.entities)[0], 'las otras patas no cambian'
    assert_equal 2, leg.instances.length
    assert_equal 104.0, legs[2].transformation.origin.x
  end

  def test_sin_hacer_unico_cambia_la_definicion_compartida_una_sola_vez
    root, _group, legs, leg = furniture
    result = Engine.new([half(1050)], false).preview(root.to_a, root, ID)
    assert result.shared
    stretch(root, [half(1050)], [V.new(10, 0, 0)], false)
    assert_same leg, legs[1].definition
    assert_equal [0.0, 14.0], extents(leg.entities)[0]
  end

  def test_copia_del_mismo_componente_fuera_de_la_seleccion_no_cambia
    root = Sketchup::Entities.new
    d = Sketchup::ComponentDefinition.new
    d.entities.add_box(0, 0, 0, 10, 10, 10)
    a = Sketchup::ComponentInstance.new(d)
    b = Sketchup::ComponentInstance.new(d, T.translation(V.new(0, 50, 0)))
    root << a << b
    Engine.new([half(5)], true).apply([a], root, ID, [V.new(7, 0, 0)])
    assert_equal [0.0, 17.0], extents(a.definition.entities)[0]
    assert_equal [0.0, 10.0], extents(b.definition.entities)[0]
  end

  def test_grupo_girado_y_escalado_se_estira_en_ejes_del_modelo
    root = Sketchup::Entities.new
    d = Sketchup::ComponentDefinition.new
    d.entities.add_box(0, 0, 0, 10, 2, 3)
    inner = Sketchup::ComponentDefinition.new
    inner.entities.add_box(0, 0, 0, 4, 1, 1)
    d.entities << Sketchup::Group.new(inner, T.translation(V.new(3, 0, 5)))
    # Girado 90° (su eje X local apunta al Y del modelo) y al doble de tamaño.
    tr = T.translation(V.new(100, 0, 0)) * T.rotation_z(Math::PI / 2) * T.scaling(2, 2, 2)
    root << Sketchup::Group.new(d, tr)
    before = extents(root)
    assert_equal [0.0, 20.0], before[1]
    region = Regions::HalfSpace.new(P.new(0, 10, 0), V.new(0, 1, 0))
    stretch(root, [region], [V.new(0, 6, 0)])
    after = extents(root)
    assert_equal [0.0, 26.0], after[1]
    assert_equal before[0], after[0]
    assert_equal before[2], after[2]
    # El grupo interior (y modelo 6..14) queda a caballo: crece 6 en el modelo,
    # que son 3 en sus propias unidades.
    assert_equal [0.0, 7.0], extents(root.first.definition.entities.to_a.last.definition.entities)[0]
  end

  def test_estirado_simetrico
    root = Sketchup::Entities.new
    root.add_box(0, 0, 0, 10, 4, 3)
    stretch(root, [half(5), half(5, -1)], [V.new(2, 0, 0), V.new(-2, 0, 0)])
    assert_equal [-2.0, 12.0], extents(root)[0]
  end

  def test_objeto_bloqueado_no_se_toca
    root, group, = furniture
    group.locked = true
    stretch(root, [half(1030)], [V.new(50, 0, 0)])
    assert_equal [1000.0, 1100.0], extents(root)[0]
  end

  def test_vista_previa_no_modifica_nada
    root, = furniture
    before = extents(root)
    result = Engine.new([half(1030)], true).preview(root.to_a, root, ID)
    assert_equal before, extents(root)
    assert_equal 4, result.vertex_count
    assert_equal 2, result.instance_count
    refute result.empty?
    assert_equal 8, result.segments.size
  end

  def test_objeto_apoyado_en_el_divisor_se_desplaza_entero
    root = Sketchup::Entities.new
    d = Sketchup::ComponentDefinition.new
    d.entities.add_box(0, 0, 0, 10, 10, 10)
    inst = Sketchup::ComponentInstance.new(d, T.translation(V.new(5, 0, 0)))
    root << inst
    stretch(root, [half(5)], [V.new(3, 0, 0)])
    assert_equal 8.0, inst.transformation.origin.x
    assert_equal [0.0, 10.0], extents(d.entities)[0]
  end

  def test_ventana_en_perspectiva
    eye = P.new(0, -100, 0)
    rays = [[-1, -1], [1, -1], [1, 1], [-1, 1]].map { |x, z| [eye, V.new(x, 10, z)] }
    f = Regions::Frustum.from_rays(rays, [eye, V.new(0, 1, 0)])
    assert f.contains?(P.new(0, 0, 0))
    assert f.contains?(P.new(9, 0, 9))
    refute f.contains?(P.new(11, 0, 0))
    refute f.contains?(P.new(0, -200, 0)), 'detrás de la cámara'
    assert f.excludes_all?([P.new(20, 0, 0), P.new(30, 5, 5)])
    refute f.excludes_all?([P.new(-20, 0, 0), P.new(20, 0, 0)])
  end

  def test_ventana_en_proyeccion_paralela
    dir = V.new(0, 1, 0)
    rays = [[0, 0], [10, 0], [10, 5], [0, 5]].map { |x, z| [P.new(x, -50, z), dir] }
    f = Regions::Frustum.from_rays(rays, [P.new(5, -50, 2.5), dir])
    assert f.contains?(P.new(5, 300, 2))
    refute f.contains?(P.new(5, 300, 6))
    assert_nil Regions::Frustum.from_rays(rays.map { rays[0] }, rays[0])
  end

  def test_ventana_estira_los_vertices_que_encierra
    root, = furniture
    dir = V.new(0, 1, 0)
    # Ventana vista de frente que encierra el extremo derecho (x 1090..1110).
    rays = [[1090, -5], [1110, -5], [1110, 20], [1090, 20]].map { |x, z| [P.new(x, -500, z), dir] }
    f = Regions::Frustum.from_rays(rays, [P.new(1100, -500, 5), dir])
    stretch(root, [f], [V.new(25, 0, 0)])
    assert_equal [1000.0, 1125.0], extents(root)[0]
  end

  def test_celda_entre_dos_divisores
    px = [P.new(5, 0, 0), V.new(1, 0, 0)]
    pz = [P.new(0, 0, 5), V.new(0, 0, 1)]
    both = Regions::Cell.new([px + [:pos], pz + [:pos]])
    only_x = Regions::Cell.new([px + [:pos], pz + [:notpos]])
    assert both.contains?(P.new(6, 0, 6))
    refute both.contains?(P.new(6, 0, 5))
    assert only_x.contains?(P.new(6, 0, 5))
    refute only_x.contains?(P.new(5, 0, 1))
    resting = [P.new(5, 0, 6), P.new(9, 0, 9)]
    assert both.contains_all?(resting), 'apoyado en el divisor cuenta como dentro'
    refute only_x.contains_all?(resting)
    assert both.excludes_all?([P.new(0, 0, 9), P.new(5, 0, 7)])
    refute both.excludes_all?([P.new(0, 0, 9), P.new(9, 0, 9)])
    mid = Regions::Cell.new([px + [:neg], pz + [:mid]])
    assert mid.contains?(P.new(1, 0, 5))
    assert mid.excludes_all?([P.new(1, 0, 6), P.new(2, 0, 9)])
  end

  def test_suma_y_resta_de_regiones
    c = Regions::Composite.new
    assert c.empty?
    c.add(half(5)).subtract(half(8))
    refute c.empty?
    assert c.contains?(P.new(6, 0, 0))
    refute c.contains?(P.new(9, 0, 0))
    refute c.contains?(P.new(1, 0, 0))
    assert c.excludes_all?([P.new(0, 0, 0), P.new(4, 0, 0)])
  end

  def test_puntos_sueltos
    s = Regions::PointSet.new([P.new(1, 1, 1), P.new(5, 1, 1)])
    assert s.contains?(P.new(5.0005, 1, 1))
    refute s.contains?(P.new(3, 1, 1))
    assert s.excludes_all?([P.new(10, 0, 0), P.new(12, 3, 3)])
  end
end
