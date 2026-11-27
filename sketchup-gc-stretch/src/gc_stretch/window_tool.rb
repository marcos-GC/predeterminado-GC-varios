# Herramienta «Estirar por ventana».
#
# Se encierran en una ventana los vértices que se quieren mover (como el
# «Estirar» de AutoCAD), sin importar en qué grupo o componente estén, y se
# desplazan con dos clics igual que con Mover. Lo que queda entero dentro de la
# ventana se traslada sin deformarse; lo que queda a caballo se alarga.

module GrupoCosmic
  module GCStretch
    class WindowTool
      include Util

      DRAG_PIXELS = 5
      MAX_POINTS = 4000
      AXES = { VK_RIGHT => [X_AXIS, 'rojo'], VK_LEFT => [Y_AXIS, 'verde'],
               VK_UP => [Z_AXIS, 'azul'] }.freeze
      AXIS_COLORS = { 'rojo' => Sketchup::Color.new(220, 0, 0),
                      'verde' => Sketchup::Color.new(0, 170, 0),
                      'azul' => Sketchup::Color.new(0, 0, 220) }.freeze
      COLOR_WINDOW = Sketchup::Color.new(0, 110, 255)

      def activate
        @model = Sketchup.active_model
        @ip1 = Sketchup::InputPoint.new
        @ip2 = Sketchup::InputPoint.new
        scope = stretchable(@model.selection.to_a)
        @scope = scope.empty? ? nil : scope
        @lock = nil
        clear_region
        @model.active_view.invalidate
      end

      def deactivate(view)
        view.invalidate
      end

      def resume(view)
        update_status
        view.invalidate
      end

      def enableVCB?
        true
      end

      def getExtents
        bb = Geom::BoundingBox.new
        if @state == :move
          bb.add(@base)
          bb.add(shift(@base, @vector))
          @preview.segments.each do |pa, ia, pb, ib|
            bb.add(shift(pa, @vector)) if ia
            bb.add(shift(pb, @vector)) if ib
          end
        end
        bb
      end

      # ---------------------------------------------------------------- ratón

      def onLButtonDown(_flags, x, y, view)
        if @state == :move
          commit(view)
        else
          @down = [x, y]
          @corner = [x, y]
          @dragging = false
        end
        view.invalidate
      end

      def onMouseMove(_flags, x, y, view)
        if @state == :move
          @ip2.pick(view, x, y, @ip1)
          target = @ip2.position
          target = target.project_to_line([@base, @lock[0]]) if @lock
          @vector = between(@base, target)
          view.tooltip = @ip2.tooltip
          Sketchup.vcb_value = @vector.length.to_l.to_s
        elsif @down
          @corner = [x, y]
          @dragging ||= Math.hypot(x - @down[0], y - @down[1]) >= DRAG_PIXELS
        elsif !@region.empty?
          @ip1.pick(view, x, y)
          view.tooltip = @ip1.tooltip
        end
        view.invalidate
      end

      def onLButtonUp(flags, x, y, view)
        return unless @down
        down = @down
        @down = nil
        operation = operation_for(flags)
        if @dragging
          @dragging = false
          region = window_region(view, down, [x, y])
          change_region(operation, region) if region
        elsif @region.empty? || operation != :replace
          region = clicked_region(view, x, y)
          change_region(operation, region) if region
        else
          start_move(view, x, y)
        end
        view.invalidate
      end

      # -------------------------------------------------------------- teclado

      def onKeyDown(key, _repeat, _flags, view)
        if AXES.key?(key)
          @lock = @lock && @lock[0] == AXES[key][0] ? nil : AXES[key]
        elsif key == VK_DOWN
          @lock = nil
        else
          return
        end
        update_status
        view.invalidate
      end

      def onUserText(text, view)
        return unless @state == :move
        value = parse_length(text)
        return UI.beep if value.nil? || @vector.length < TOL
        @vector = scaled(@vector, value / @vector.length)
        commit(view)
        view.invalidate
      end

      def onCancel(reason, view)
        if @state == :move && reason != 2
          @state = :select
          update_status
        else
          clear_region
        end
        @down = nil
        @dragging = false
        view.invalidate
      end

      def getMenu(menu)
        item = menu.add_item('Hacer únicos los componentes que se deformen') do
          Settings.toggle_make_unique
          refresh_preview
          @model.active_view.invalidate
        end
        menu.set_validation_proc(item) { Settings.make_unique? ? MF_CHECKED : MF_UNCHECKED }
        menu.add_item('Quitar la selección de vértices') do
          clear_region
          @model.active_view.invalidate
        end
      end

      # --------------------------------------------------------------- dibujo

      def draw(view)
        view.line_stipple = ''
        color = preview_color(@preview)
        unless @preview.empty?
          vectors = [@state == :move ? @vector : Geom::Vector3d.new(0, 0, 0)]
          lines = preview_lines(@preview, vectors)
          view.line_width = @state == :move ? 1 : 2
          view.drawing_color = color
          view.draw(GL_LINES, lines) unless lines.empty?
          points = marked_points(vectors[0])
          view.draw_points(points, 7, 2, color) unless points.empty?
        end
        if @state == :move
          view.line_width = 2
          view.line_stipple = '-'
          view.drawing_color = @lock ? AXIS_COLORS[@lock[1]] : color
          view.draw(GL_LINES, [@base, shift(@base, @vector)])
          view.line_stipple = ''
          @ip2.draw(view)
        elsif @dragging
          draw_window(view)
        elsif !@region.empty? && @ip1.valid?
          @ip1.draw(view)
        end
      end

      private

      def roots
        @scope ? @scope.select(&:valid?) : @model.active_entities.to_a
      end

      # ------------------------------------------------------------ selección

      def operation_for(flags)
        if (flags & CONSTRAIN_MODIFIER_MASK) != 0
          :subtract
        elsif (flags & COPY_MODIFIER_MASK) != 0
          :add
        else
          :replace
        end
      end

      def window_region(view, a, b)
        x0, x1 = [a[0], b[0]].minmax
        y0, y1 = [a[1], b[1]].minmax
        return nil if x1 - x0 < 2 || y1 - y0 < 2
        rays = [[x0, y0], [x1, y0], [x1, y1], [x0, y1]].map { |x, y| view.pickray(x, y) }
        Regions::Frustum.from_rays(rays, view.pickray((x0 + x1) / 2.0, (y0 + y1) / 2.0))
      end

      # Vértices de la arista o cara en la que se hizo clic, esté al nivel que esté.
      def clicked_region(view, x, y)
        helper = view.pick_helper
        helper.do_pick(x, y)
        found = nil
        helper.count.times do |i|
          leaf = helper.leaf_at(i)
          if leaf.is_a?(Sketchup::Edge)
            found = i
            break
          elsif leaf.is_a?(Sketchup::Face)
            found ||= i
          end
        end
        return nil unless found
        tr = path_transformation(helper.path_at(found))
        Regions::PointSet.new(helper.leaf_at(found).vertices.map { |v| v.position.transform(tr) })
      end

      # Con un grupo abierto para editar, SketchUp ya da en coordenadas del
      # modelo lo que hay en ese grupo; solo se acumula lo que cuelga de él.
      def path_transformation(path)
        open_path = @model.active_path || []
        tr = IDENTITY
        path[0...-1].each do |entity|
          next if open_path.include?(entity)
          tr *= entity.transformation
        end
        tr
      end

      def change_region(operation, region)
        if operation == :replace
          @region = Regions::Composite.new.add(region)
        elsif operation == :add
          @region.add(region)
        else
          @region.subtract(region)
        end
        refresh_preview
      end

      def clear_region
        @region = Regions::Composite.new
        @state = :select
        @vector = Geom::Vector3d.new(0, 0, 0)
        refresh_preview
      end

      def refresh_preview
        @engine = Engine.new([@region], Settings.make_unique?)
        @preview = if @region.empty?
                     Engine::Preview.new([], [], false, false, 0, 0, 0)
                   else
                     @engine.preview(roots, @model.active_entities, IDENTITY)
                   end
        update_status
      end

      # ------------------------------------------------------------ estirado

      def start_move(view, x, y)
        return UI.beep if @preview.empty?
        @ip1.pick(view, x, y)
        return unless @ip1.valid?
        @base = @ip1.position
        @vector = Geom::Vector3d.new(0, 0, 0)
        @state = :move
        update_status
      end

      def commit(view)
        if @vector.length >= TOL
          vector = @vector
          list = roots
          run_stretch(@model, 'Estirar por ventana') do
            @engine.apply(list, @model.active_entities, IDENTITY, [vector])
          end
        end
        clear_region
        view.invalidate
      end

      # -------------------------------------------------------------- avisos

      def update_status
        lock = @lock ? " Bloqueado al eje #{@lock[1]}." : ''
        if @state == :move
          Sketchup.vcb_label = 'Distancia'
          Sketchup.status_text =
            'Mueve y haz clic en el punto de destino, o escribe la distancia. ' \
            "Flechas = bloquear eje (abajo lo suelta).#{lock}#{preview_note(@preview)}"
        elsif @region.empty?
          Sketchup.vcb_label = ''
          Sketchup.vcb_value = ''
          Sketchup.status_text =
            'Arrastra una ventana alrededor de los vértices que quieres mover, o ' \
            'haz clic en una arista o cara.' \
            "#{@scope ? ' Solo se estira lo que estaba seleccionado.' : ''}"
        else
          Sketchup.vcb_label = ''
          Sketchup.status_text =
            "#{@preview.vertex_count} vértices y #{@preview.instance_count} objetos " \
            'enteros. Haz clic en el punto de partida del estirado. Ctrl (Opción en Mac) = añadir, ' \
            "Mayús = quitar, arrastrar = ventana nueva.#{lock}#{preview_note(@preview)}"
        end
      end

      def marked_points(vector)
        points = []
        @preview.segments.each do |pa, ia, pb, ib|
          points << shift(pa, vector) if ia
          points << shift(pb, vector) if ib
          break if points.size >= MAX_POINTS
        end
        points
      end

      def draw_window(view)
        x0, y0 = @down
        x1, y1 = @corner
        corners = [[x0, y0], [x1, y0], [x1, y1], [x0, y1]].map do |x, y|
          Geom::Point3d.new(x, y, 0)
        end
        view.line_width = 1
        view.drawing_color = COLOR_WINDOW
        view.draw2d(GL_LINE_LOOP, corners)
      end
    end
  end
end
