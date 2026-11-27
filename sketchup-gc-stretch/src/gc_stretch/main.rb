# Carga el código de GC Stretch y crea el menú y la barra de herramientas.

require 'sketchup.rb'

module GrupoCosmic
  module GCStretch
    directory = File.dirname(__FILE__)
    %w[regions engine common stretch_box box_tool window_tool].each do |name|
      Sketchup.require(File.join(directory, name))
    end

    unless file_loaded?(__FILE__)
      icons = File.join(directory, 'icons')

      box = UI::Command.new('Estirar por caja') do
        Sketchup.active_model.select_tool(BoxTool.new)
      end
      box.tooltip = 'Estirar por caja'
      box.status_bar_text =
        'Estira la selección con tiradores y un plano divisor, sin deformar lo que no lo cruza.'
      box.small_icon = File.join(icons, 'box_24.png')
      box.large_icon = File.join(icons, 'box_32.png')

      window = UI::Command.new('Estirar por ventana') do
        Sketchup.active_model.select_tool(WindowTool.new)
      end
      window.tooltip = 'Estirar por ventana'
      window.status_bar_text =
        'Encierra vértices en una ventana y arrástralos, aunque estén dentro de grupos.'
      window.small_icon = File.join(icons, 'window_24.png')
      window.large_icon = File.join(icons, 'window_32.png')

      unique = UI::Command.new('Hacer únicos los componentes que se deformen') do
        Settings.toggle_make_unique
      end
      unique.set_validation_proc { Settings.make_unique? ? MF_CHECKED : MF_UNCHECKED }
      unique.status_bar_text =
        'Si se desmarca, estirar un componente cambia todas sus copias.'

      menu = UI.menu('Extensions').add_submenu('GC Stretch')
      menu.add_item(box)
      menu.add_item(window)
      menu.add_separator
      menu.add_item(unique)

      toolbar = UI::Toolbar.new('GC Stretch')
      toolbar.add_item(box)
      toolbar.add_item(window)
      toolbar.restore

      UI.add_context_menu_handler do |context|
        selection = Sketchup.active_model.selection
        if selection.any? { |e| e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) }
          context.add_item(box)
          context.add_item(window)
        end
      end

      file_loaded(__FILE__)
    end
  end
end
