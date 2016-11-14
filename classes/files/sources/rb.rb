require_relative '../source'

module Rue
  class RbFile < SourceFile

    def object?
      return false
    end
  end
end
