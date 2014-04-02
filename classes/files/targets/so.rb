require_relative 'base'

module Rue
	class SOFile < TargetFile
		
		def initialize(project, name, options = {})
			super(project, name, options)
		end
		
		def linkname
			return "-l#{@name.sub(/\.[^.]*\Z/, '').sub(/.*\/lib/, '')}"
		end
	end
end
