require_relative 'base'

module Rue
	class LibFile < TargetFile
		
		def initialize(project, filename)
			super(project, filename, :lib)
		end
		
		def linkname
			return "-l#{@name.sub(/\.[^.]*\Z/, '').sub(/\Alib/, '')}"
		end
	end
end
