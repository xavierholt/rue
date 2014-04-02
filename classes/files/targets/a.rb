require_relative 'base'

module Rue
	class AFile < TargetFile
		
		def initialize(project, name, options = {})
			super(project, name, options)
		end
		
		def linkname
			return @name
		end
	end
end
