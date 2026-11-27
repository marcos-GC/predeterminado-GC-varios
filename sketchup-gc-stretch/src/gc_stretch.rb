# GC Stretch — estirar grupos y componentes de SketchUp sin deformarlos.
# Cargador de la extensión: solo la registra; el código está en gc_stretch/.

require 'sketchup.rb'
require 'extensions.rb'

module GrupoCosmic
  module GCStretch
    VERSION = '1.1.0'.freeze

    unless file_loaded?(__FILE__)
      extension = SketchupExtension.new('GC Stretch', 'gc_stretch/main')
      extension.version = VERSION
      extension.creator = 'Grupo Cosmic'
      extension.copyright = '2026 Grupo Cosmic'
      extension.description =
        'Estira grupos y componentes moviendo solo una parte de sus vértices: ' \
        'por caja con tiradores y plano divisor, o por ventana de selección.'
      Sketchup.register_extension(extension, true)
      file_loaded(__FILE__)
    end
  end
end
