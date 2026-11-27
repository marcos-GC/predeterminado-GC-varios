# Herramienta «Estirar por caja».
#
# Envuelve la selección en una caja con tiradores y planos divisores. Al
# arrastrar un tirador se desplaza todo lo que queda entre el divisor y ese
# tirador; el otro lado no se mueve y solo se alarga lo que cruza el divisor.
# Los tiradores de las caras estiran un eje; los de las esquinas, todos a la
# vez, cada eje con su propio divisor. Con el modo simétrico se abren los dos
# lados.

module GrupoCosmic
  module GCStretch
    class BoxTool
      include Util

      HANDLE_PIXELS = 14
      DIVIDER_PIXELS = 7
      DRAG_PIXELS = 10
      TAB_KEYS = (Sketchup.platform == :platform_osx ? [9, 48] : [9]).freeze
      AXIS_NAMES = %w[rojo verde azul].freeze

      COLOR_BOX = Sketchup::Color.new(255, 140, 0)
      COLOR_HANDLE = Sketchup::Color.new(0, 150, 60)
      COLOR_CORNER = Sketchup::Color.new(0, 90, 200)
      COLOR_HOT = Sketchup::Color.new(230, 30, 30)
      COLOR_DIVIDER = Sketchup::Color.new(200, 0, 200)
      COLOR_DIVIDER_FILL = Sketchup::Color.new(200, 0, 200, 40)

      def activate
        @model = Sketchup.active_model
        @ip = Sketchup::InputPoint.new
        @symmetric = false
        @model_axes = false
        @wanted_divider = [nil, nil, nil]
        rebuild
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
        if @box
          @box.corners.each { |c| bb.add(c) }
          @box.grown(@handle, @growth, @symmetric).each { |c| bb.add(c) } if @state == :drag
        end
        bb
      end

      # ---------------------------------------------------------------- ratón

      def onMouseMove(_flags, x, y, view)
        case @state
        when :idle
          @hover = handle_at(view, x, y)
          @active_axes = @hover.axes if @hover
          @hover_divider = @hover ? nil : divider_at(view, x, y)
          view.tooltip = if @hover && @hover.corner?
                           'Clic y mover para estirar por esta esquina'
                         elsif @hover
                           'Clic y mover para estirar por este lado'
                         elsif @hover_divider
                           'Clic para mover el divisor; doble clic para centrarlo'
                         else
                           ''
                         end
        when :drag
          @growth = growth_at(view, x, y)
          show_growth
        when :divider
          k = @divider_axis
          @wanted_divider[k] = divider_at_cursor(view, x, y)
          Sketchup.vcb_value = (divider(k) - @box.min[k]).to_l.to_s
        end
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        @down = [x, y]
        case @state
        when :idle
          if @box && (handle = handle_at(view, x, y))
            start_drag(handle)
          elsif @box && (axis = divider_at(view, x, y))
            @divider_axis = axis
            @state = :divider
            @fresh = true
            update_status
          else
            pick_selection(flags, x, y, view)
          end
        when :drag
          @fresh = false
          commit(@growth)
        when :divider
          @fresh = false
          @state = :idle
          update_status
        end
        view.invalidate
      end

      # Permite también pulsar, arrastrar y soltar.
      def onLButtonUp(_flags, x, y, view)
        return unless @fresh && @down
        return if Math.hypot(x - @down[0], y - @down[1]) < DRAG_PIXELS
        @fresh = false
        if @state == :drag
          commit(@growth)
        elsif @state == :divider
          @state = :idle
          update_status
        end
        view.invalidate
      end

      def onLButtonDoubleClick(_flags, x, y, view)
        return unless @box
        axis = @state == :divider ? @divider_axis : divider_at(view, x, y)
        return unless axis
        @wanted_divider[axis] = nil
        @state = :idle
        update_status
        view.invalidate
      end

      # -------------------------------------------------------------- teclado

      def onKeyDown(key, _repeat, _flags, view)
        if key == COPY_MODIFIER_KEY
          # Windows repite el aviso mientras la tecla sigue pulsada.
          toggle_symmetric unless @modifier_down
          @modifier_down = true
        elsif key == VK_UP
          use_axes(true)
        elsif key == VK_DOWN
          use_axes(false)
        elsif TAB_KEYS.include?(key) && @state == :drag
          ask_dimension
        end
        view.invalidate
      end

      def onKeyUp(key, _repeat, _flags, _view)
        @modifier_down = false if key == COPY_MODIFIER_KEY
      end

      def onUserText(text, view)
        if @state == :drag
          totals = typed_totals(text)
          return UI.beep if totals.nil?
          commit_totals(totals)
        elsif @state == :divider
          value = parse_length(text)
          return UI.beep if value.nil?
          k = @divider_axis
          @wanted_divider[k] = @box.min[k] + value
          @state = :idle
          update_status
        end
        view.invalidate
      end

      def onCancel(reason, view)
        if reason == 2 # deshacer: la geometría cambia después de este aviso
          UI.start_timer(0, false) do
            rebuild
            view.invalidate
          end
        elsif @state == :idle
          @model.selection.clear
          rebuild
        else
          @state = :idle
          update_status
        end
        view.invalidate
      end

      def getMenu(menu)
        item = menu.add_item('Estirado simétrico (dos lados)') { toggle_symmetric }
        menu.set_validation_proc(item) { @symmetric ? MF_CHECKED : MF_UNCHECKED }
        menu.add_item(@model_axes ? 'Usar los ejes del objeto' : 'Usar los ejes del modelo') do
          use_axes(!@model_axes)
        end
        menu.add_item('Divisores al centro') do
          @wanted_divider = [nil, nil, nil]
          @model.active_view.invalidate
        end
        menu.add_item('Medida exacta…') { ask_dimension } if @state == :drag
        menu.add_separator
        item = menu.add_item('Hacer únicos los componentes que se deformen') do
          Settings.toggle_make_unique
          refresh_preview if @state == :drag
        end
        menu.set_validation_proc(item) { Settings.make_unique? ? MF_CHECKED : MF_UNCHECKED }
      end

      # --------------------------------------------------------------- dibujo

      def draw(view)
        return unless @box
        view.line_stipple = ''
        view.line_width = 2
        view.drawing_color = COLOR_BOX
        view.draw(GL_LINES, box_lines(@box.corners))
        @active_axes.each { |k| draw_divider(view, k) }
        if @state == :drag
          view.line_width = 1
          view.drawing_color = preview_color(@preview)
          lines = preview_lines(@preview, vectors_for(@growth))
          view.draw(GL_LINES, lines) unless lines.empty?
          view.line_width = 2
          view.line_stipple = '-'
          view.draw(GL_LINES, box_lines(@box.grown(@handle, @growth, @symmetric)))
          view.line_stipple = ''
          @ip.draw(view) if @snapped
        end
        draw_handles(view)
      end

      private

      def items
        stretchable(@model.selection.to_a)
      end

      # ----------------------------------------------------- caja y divisores

      def rebuild
        @state = :idle
        @fresh = false
        @hover = nil
        @hover_divider = nil
        @handle = nil
        @growth = [0.0, 0.0, 0.0]
        list = items
        if list != @boxed_items
          @wanted_divider = [nil, nil, nil]
          @boxed_items = list
        end
        points = list.flat_map { |e| entity_points(e) }
        @box = points.empty? ? nil : StretchBox.new(frame_for(list), points)
        @active_axes = if @box.nil?
                         []
                       elsif @active_axes.nil? || @active_axes.empty?
                         [@box.longest_axis]
                       else
                         @active_axes
                       end
        update_status
      end

      def entity_points(entity)
        if instance?(entity)
          b = entity.definition.bounds
          return [] if b.empty?
          (0..7).map { |i| b.corner(i).transform(entity.transformation) }
        elsif entity.is_a?(Sketchup::Image)
          (0..7).map { |i| entity.bounds.corner(i) }
        else
          entity.vertices.map(&:position)
        end
      end

      # Con un solo grupo o componente, la caja sigue sus propios ejes (así un
      # mueble girado se estira a lo largo de sí mismo); si no, los del modelo.
      def frame_for(list)
        unless @model_axes || list.size != 1 || !instance?(list[0])
          t = list[0].transformation
          axes = [t.xaxis, t.yaxis, t.zaxis]
          if axes.all? { |a| a.length > 1.0e-9 }
            axes = axes.map(&:normalize)
            square = axes[0].dot(axes[1]).abs < 1.0e-6 &&
                     axes[0].dot(axes[2]).abs < 1.0e-6 &&
                     axes[1].dot(axes[2]).abs < 1.0e-6
            return axes if square
          end
        end
        [X_AXIS, Y_AXIS, Z_AXIS]
      end

      def divider(k)
        @box.divider(k, @wanted_divider[k])
      end

      def same_handle?(a, b)
        a && b && a.sides == b.sides
      end

      def handle_at(view, x, y)
        return nil unless @box
        best = nil
        best_distance = HANDLE_PIXELS
        @box.handles.each do |h|
          s = view.screen_coords(h.position)
          d = Math.hypot(s.x - x, s.y - y)
          if d < best_distance
            best = h
            best_distance = d
          end
        end
        best
      end

      # Eje del divisor cuyo borde está bajo el cursor, o nil.
      def divider_at(view, x, y)
        return nil unless @box
        @active_axes.find do |k|
          next false if @box.size(k) < TOL
          c = @box.divider_corners(k, divider(k))
          (0..3).any? do |i|
            screen_distance_to_segment(view, x, y, c[i], c[(i + 1) % 4]) < DIVIDER_PIXELS
          end
        end
      end

      def divider_at_cursor(view, x, y)
        k = @divider_axis
        @ip.pick(view, x, y)
        @snapped = @ip.valid? && @ip.degrees_of_freedom < 3
        target = if @snapped
                   @ip.position
                 else
                   line = [@box.point(@box.center), @box.frame[k]]
                   Geom.closest_points(line, view.pickray(x, y))[0]
                 end
        [[@box.coord(target, k), @box.min[k]].max, @box.max[k]].min
      end

      # ------------------------------------------------------------ estirado

      def start_drag(handle)
        @handle = handle
        @active_axes = handle.axes
        @growth = [0.0, 0.0, 0.0]
        @snapped = false
        @state = :drag
        @fresh = true
        refresh_preview
        update_status
      end

      # Vector que apunta hacia fuera de la caja por el lado del tirador.
      def outward(k)
        scaled(@box.frame[k], @handle.sides[k])
      end

      # Cada eje del tirador parte el espacio con su divisor; las celdas que
      # resultan se mueven según a qué lado de cada divisor estén. @cells
      # guarda, por celda, el signo del desplazamiento en cada eje.
      def refresh_preview
        axes = @handle.axes
        states = @symmetric ? [:pos, :neg, :mid] : [:pos, :notpos]
        signs = { pos: 1, neg: -1, mid: 0, notpos: 0 }
        @cells = []
        regions = []
        states.repeated_permutation(axes.size).each do |combo|
          next if combo.all? { |state| signs[state].zero? }
          constraints = axes.each_with_index.map do |k, i|
            [@box.divider_point(k, divider(k)), outward(k), combo[i]]
          end
          regions << Regions::Cell.new(constraints)
          cell = [0, 0, 0]
          axes.each_with_index { |k, i| cell[k] = signs[combo[i]] }
          @cells << cell
        end
        @engine = Engine.new(regions, Settings.make_unique?)
        @preview = @engine.preview(items, @model.active_entities, IDENTITY)
        update_status
      end

      # Cuánto sale el tirador hacia fuera en cada eje según el cursor
      # (negativo = encoge).
      def growth_at(view, x, y)
        origin = @handle.position
        @ip.pick(view, x, y)
        @snapped = @ip.valid? && @ip.degrees_of_freedom < 2
        view.tooltip = @snapped ? @ip.tooltip : ''
        target = @snapped ? @ip.position : free_target(view, x, y)
        growth = [0.0, 0.0, 0.0]
        @handle.axes.each do |k|
          g = between(origin, target).dot(@box.frame[k]) * @handle.sides[k]
          growth[k] = g.abs < 1.0e-9 ? 0.0 : g
        end
        growth
      end

      # Sin referencia del modelo: un tirador de cara se mueve por su eje; uno
      # de esquina, por la cara de la caja que mejor se ve desde la cámara (el
      # eje perpendicular a esa cara solo cambia ajustando a un punto o
      # escribiendo la medida).
      def free_target(view, x, y)
        origin = @handle.position
        axes = @handle.axes
        ray = view.pickray(x, y)
        if axes.size == 1
          return Geom.closest_points([origin, @box.frame[axes[0]]], ray)[0]
        end
        looking = view.camera.direction
        normal = if axes.size == 2
                   @box.frame[([0, 1, 2] - axes)[0]]
                 else
                   @box.frame[axes.max_by { |k| @box.frame[k].dot(looking).abs }]
                 end
        Geom.intersect_line_plane(ray, [origin, normal]) || origin
      end

      def vectors_for(growth)
        @cells.map do |cell|
          v = Geom::Vector3d.new(0, 0, 0)
          @handle.axes.each do |k|
            step = scaled(outward(k), growth[k] * cell[k])
            v = Geom::Vector3d.new(v.x + step.x, v.y + step.y, v.z + step.z)
          end
          v
        end
      end

      def factor
        @symmetric ? 2.0 : 1.0
      end

      def show_growth
        Sketchup.vcb_value =
          @handle.axes.map { |k| (@growth[k] * factor).to_l.to_s }.join('; ')
      end

      # Una medida, o una por eje del tirador separadas por punto y coma. Con
      # «=» delante son medidas finales; sin él, lo que crece cada una.
      def typed_totals(text)
        text = text.strip
        final = text.start_with?('=')
        text = text[1..-1] if final
        axes = @handle.axes
        values = text.split(/\s*;\s*|\s+/).reject(&:empty?).map { |t| parse_length(t) }
        values *= axes.size if values.size == 1
        return nil if values.size != axes.size || values.include?(nil)
        totals = [0.0, 0.0, 0.0]
        axes.each_with_index do |k, i|
          totals[k] = final ? values[i] - @box.size(k) : values[i]
        end
        totals
      end

      # totals[k]: lo que debe crecer la medida completa de la caja en el eje k.
      def commit_totals(totals)
        commit(totals.map { |t| t / factor })
      end

      def commit(growth)
        if growth.any? { |g| g.abs >= TOL } && !@preview.empty?
          vectors = vectors_for(growth)
          list = items
          run_stretch(@model, 'Estirar por caja') do
            @engine.apply(list, @model.active_entities, IDENTITY, vectors)
          end
        end
        rebuild
      end

      def ask_dimension
        return unless @state == :drag
        axes = @handle.axes
        prompts = axes.map { |k| "Medida nueva (eje #{AXIS_NAMES[k]}) " }
        answer = UI.inputbox(prompts, axes.map { |k| @box.size(k).to_l.to_s }, 'GC Stretch')
        return unless answer
        values = answer.map { |t| parse_length(t) }
        return UI.beep if values.any? { |v| v.nil? || v <= 0 }
        totals = [0.0, 0.0, 0.0]
        axes.each_with_index { |k, i| totals[k] = values[i] - @box.size(k) }
        commit_totals(totals)
        @model.active_view.invalidate
      end

      def toggle_symmetric
        @symmetric = !@symmetric
        @state == :drag ? refresh_preview : update_status
      end

      def use_axes(model_axes)
        return unless @state == :idle
        @model_axes = model_axes
        @wanted_divider = [nil, nil, nil]
        @active_axes = nil
        rebuild
      end

      def pick_selection(flags, x, y, view)
        helper = view.pick_helper
        helper.do_pick(x, y)
        picked = helper.best_picked
        selection = @model.selection
        if (flags & COPY_MODIFIER_MASK) != 0
          selection.toggle(picked) if picked
        else
          selection.clear
          selection.add(picked) if picked
        end
        @active_axes = nil
        rebuild
      end

      # -------------------------------------------------------------- avisos

      def update_status
        mode = @symmetric ? ' [SIMÉTRICO]' : ''
        case @state
        when :drag
          Sketchup.vcb_label = 'Estirar'
          show_growth
          typing = if @handle.corner?
                     'Escribe cuánto crece (una medida, o una por eje separadas ' \
                     'por «;»), o =medidas para las finales'
                   else
                     'Escribe cuánto crece, o =medida para la medida final'
                   end
          Sketchup.status_text =
            "Mueve y haz clic para estirar#{mode}. #{typing} (Tab abre un " \
            "cuadro).#{preview_note(@preview)}"
        when :divider
          Sketchup.vcb_label = 'Divisor'
          Sketchup.status_text =
            'Mueve el divisor (se ajusta a los puntos del modelo) y haz clic, o ' \
            'escribe su distancia al borde de la caja.'
        else
          Sketchup.vcb_label = ''
          Sketchup.vcb_value = ''
          Sketchup.status_text =
            if @box
              'Clic en un tirador: verde = un lado, azul = esquina (varios ejes ' \
              "a la vez)#{mode}. Los planos morados son los divisores: lo que " \
              'los cruza se alarga, el resto se desplaza. Ctrl (Opción en Mac) ' \
              '= simétrico. Flechas arriba/abajo = ejes.'
            else
              'Haz clic en un grupo o componente para estirarlo.'
            end
        end
      end

      def draw_divider(view, k)
        return if @box.size(k) < TOL
        c = @box.divider_corners(k, divider(k))
        moving = @state == :divider && @divider_axis == k
        view.drawing_color = COLOR_DIVIDER_FILL
        view.draw(GL_QUADS, c)
        view.drawing_color = COLOR_DIVIDER
        view.line_width = @hover_divider == k || moving ? 4 : 2
        view.draw(GL_LINE_LOOP, c)
        @ip.draw(view) if moving && @snapped
      end

      def draw_handles(view)
        hot = @state == :drag ? @handle : @hover
        rest = @box.handles.reject { |h| same_handle?(h, hot) }
        faces, corners = rest.partition { |h| !h.corner? }
        view.draw_points(faces.map(&:position), 12, 2, COLOR_HANDLE) unless faces.empty?
        view.draw_points(corners.map(&:position), 10, 2, COLOR_CORNER) unless corners.empty?
        return unless hot
        position = hot.position
        if @state == :drag
          hot.axes.each { |k| position = shift(position, scaled(outward(k), @growth[k])) }
        end
        view.draw_points([position], 16, 2, COLOR_HOT)
      end
    end
  end
end
