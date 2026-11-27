# Prueba de humo de las dos herramientas con una vista simulada:
#   ruby test/test_tools.rb
require 'minitest/autorun'
require_relative 'ui_stub'
%w[regions engine common stretch_box box_tool window_tool].each do |f|
  require_relative "../src/gc_stretch/#{f}"
end

class ToolsTest < Minitest::Test
  include GrupoCosmic::GCStretch

  V = Geom::Vector3d
  T = Geom::Transformation

  # Tablero de 100 con tres patas de 4 (en x local 2, 48 y 94), colocado en x=1000.
  def setup
    @model = Sketchup::Model.new
    Sketchup.active_model = @model
    Sketchup.write_default('', 'make_unique', true)
    cabinet = Sketchup::ComponentDefinition.new
    cabinet.entities.add_box(0, 0, 100, 100, 20, 20)
    @leg = Sketchup::ComponentDefinition.new
    @leg.entities.add_box(0, 0, 0, 4, 4, 100)
    @legs = [2, 48, 94].map do |x|
      i = Sketchup::ComponentInstance.new(@leg, T.translation(V.new(x, 0, 0)))
      cabinet.entities << i
      i
    end
    @group = Sketchup::Group.new(cabinet, T.translation(V.new(1000, 0, 0)))
    @model.active_entities << @group
    @view = @model.active_view
  end

  def x_range(entities = @model.active_entities, tr = T.new)
    xs = []
    entities.each do |e|
      if e.is_a?(Sketchup::Edge)
        e.vertices.each { |v| xs << v.position.transform(tr).x.round(6) }
      elsif e.is_a?(Sketchup::ComponentInstance)
        xs.concat(x_range(e.definition.entities, tr * e.transformation))
      end
    end
    xs.minmax
  end

  def leg_origins
    @legs.map { |l| l.transformation.origin.x.round(6) }
  end

  def box_tool
    @model.selection.add(@group)
    tool = BoxTool.new
    tool.activate
    tool.draw(@view)
    tool
  end

  # El tirador derecho está en el centro de la cara x=1100: pantalla (1100, -60).
  def grab_right_handle(tool)
    tool.onMouseMove(0, 1100, -60, @view)
    tool.onLButtonDown(0, 1100, -60, @view)
    tool.onLButtonUp(0, 1100, -60, @view)
  end

  def test_caja_clic_mover_clic
    tool = box_tool
    grab_right_handle(tool)
    tool.onMouseMove(0, 1130, -60, @view)
    tool.draw(@view)
    tool.getExtents
    assert_equal '30.0', Sketchup.vcb_value
    assert_equal [1000.0, 1100.0], x_range, 'la vista previa no toca el modelo'
    tool.onLButtonDown(0, 1130, -60, @view)
    assert_equal [1000.0, 1130.0], x_range
    # Divisor en el centro (x=1050): corta la pata central, que crece; la
    # izquierda no se mueve y la derecha se desplaza entera.
    assert_equal [2.0, 48.0, 124.0], leg_origins
    refute_same @leg, @legs[1].definition
    assert_same @leg, @legs[2].definition
    assert_equal ['Estirar por caja'], @model.operations
    tool.draw(@view)
  end

  def test_caja_pulsar_arrastrar_soltar
    tool = box_tool
    tool.onMouseMove(0, 1100, -60, @view)
    tool.onLButtonDown(0, 1100, -60, @view)
    tool.onMouseMove(0, 1080, -60, @view)
    tool.onLButtonUp(0, 1080, -60, @view)
    assert_equal [1000.0, 1080.0], x_range
  end

  def test_caja_medida_final_escrita
    tool = box_tool
    grab_right_handle(tool)
    tool.onUserText('=150', @view)
    assert_equal [1000.0, 1150.0], x_range
    grab_right_handle_at(tool, 1150)
    tool.onUserText('-20', @view)
    assert_equal [1000.0, 1130.0], x_range
  end

  def grab_right_handle_at(tool, x)
    tool.onMouseMove(0, x, -60, @view)
    tool.onLButtonDown(0, x, -60, @view)
    tool.onLButtonUp(0, x, -60, @view)
  end

  def test_caja_simetrica
    tool = box_tool
    tool.onKeyDown(COPY_MODIFIER_KEY, 1, 0, @view)
    tool.onKeyDown(COPY_MODIFIER_KEY, 1, 0, @view) # repetición de Windows
    tool.onKeyUp(COPY_MODIFIER_KEY, 1, 0, @view)
    grab_right_handle(tool)
    tool.onMouseMove(0, 1110, -60, @view)
    tool.draw(@view)
    assert_equal '20.0', Sketchup.vcb_value
    tool.onLButtonDown(0, 1110, -60, @view)
    assert_equal [990.0, 1110.0], x_range
  end

  def test_caja_mover_el_divisor_evita_deformar_la_pata_central
    tool = box_tool
    tool.onMouseMove(0, 1100, -60, @view) # activa el eje X
    # Borde lateral del divisor: en pantalla, la vertical x=1050.
    tool.onMouseMove(0, 1050, -30, @view)
    tool.onLButtonDown(0, 1050, -30, @view)
    tool.onLButtonUp(0, 1050, -30, @view)
    tool.onMouseMove(0, 1030, -30, @view)
    tool.draw(@view)
    tool.onLButtonDown(0, 1030, -30, @view)
    grab_right_handle(tool)
    tool.onUserText('50', @view)
    assert_equal [1000.0, 1150.0], x_range
    assert_equal [2.0, 98.0, 144.0], leg_origins
    assert_equal 3, @leg.instances.length, 'ninguna pata se deforma'
  end

  def test_caja_escape_y_seleccion_con_clic
    tool = box_tool
    grab_right_handle(tool)
    tool.onCancel(0, @view)
    tool.onCancel(0, @view)
    assert_empty @model.selection.to_a
    tool.draw(@view)
    @view.pick_helper.best_picked = @group
    tool.onLButtonDown(0, 1050, -60, @view)
    assert_equal [@group], @model.selection.to_a
    tool.getMenu(FakeMenu.new)
  end

  def test_ventana_estira_el_extremo
    tool = WindowTool.new
    tool.activate
    tool.draw(@view)
    # Ventana alrededor del extremo derecho (x 1090..1110, z -50..130).
    tool.onLButtonDown(0, 1090, -130, @view)
    tool.onMouseMove(0, 1110, 50, @view)
    tool.draw(@view)
    tool.onLButtonUp(0, 1110, 50, @view)
    tool.draw(@view)
    assert_match(/4 vértices y 1 objetos enteros/, Sketchup.status_text)
    # Clic en el punto de partida, mover 25 y clic en el destino.
    tool.onLButtonDown(0, 1100, -110, @view)
    tool.onLButtonUp(0, 1100, -110, @view)
    tool.onMouseMove(0, 1125, -110, @view)
    tool.draw(@view)
    tool.getExtents
    assert_equal [1000.0, 1100.0], x_range
    tool.onLButtonDown(0, 1125, -110, @view)
    assert_equal [1000.0, 1125.0], x_range
    assert_equal [2.0, 48.0, 119.0], leg_origins
    assert_equal 3, @leg.instances.length
    assert_equal ['Estirar por ventana'], @model.operations
  end

  def test_ventana_distancia_escrita_y_bloqueo_de_eje
    tool = WindowTool.new
    tool.activate
    tool.onLButtonDown(0, 1090, -130, @view)
    tool.onMouseMove(0, 1110, 50, @view)
    tool.onLButtonUp(0, 1110, 50, @view)
    tool.onLButtonDown(0, 1100, -110, @view)
    tool.onLButtonUp(0, 1100, -110, @view)
    tool.onKeyDown(VK_RIGHT, 1, 0, @view)
    tool.onMouseMove(0, 1105, -40, @view) # en diagonal: el bloqueo deja solo X
    tool.draw(@view)
    tool.onUserText('12', @view)
    assert_equal [1000.0, 1112.0], x_range
    tool.onCancel(0, @view)
    tool.getMenu(FakeMenu.new)
  end

  def test_ventana_restar_y_escape
    tool = WindowTool.new
    tool.activate
    tool.onLButtonDown(0, 990, -130, @view)
    tool.onMouseMove(0, 1110, 50, @view)
    tool.onLButtonUp(0, 1110, 50, @view)
    assert_match(/1 objetos enteros/, Sketchup.status_text)
    tool.onLButtonDown(0, 990, -130, @view)
    tool.onMouseMove(0, 1080, 50, @view)
    tool.onLButtonUp(CONSTRAIN_MODIFIER_MASK, 1080, 50, @view)
    assert_match(/4 vértices y 1 objetos enteros/, Sketchup.status_text)
    tool.onCancel(0, @view)
    assert_match(/Arrastra una ventana/, Sketchup.status_text)
  end

  class FakeMenu
    def add_item(_name)
      yield if false
      :item
    end

    def set_validation_proc(_item)
      yield
    end

    def add_separator; end
  end
end
