require_relative '../target'

module Rue
  class SOFile < TargetFile

    def linkname
      return "-l#{@name.sub(/\.[^.]*\Z/, '').sub(/.*\/lib/, '')}"
    end
  end
end
