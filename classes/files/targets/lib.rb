require_relative '../target'

module Rue
  class LibFile < TargetFile
    def linkname
      return "-l#{@name.sub(/\.[^.]*\Z/, '').sub(/\Alib/, '')}"
    end
  end
end
