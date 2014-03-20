require_relative 'base'

module Rue
	class OutFile < TargetFile
		
		def initialize(project, name, options)
			super(project, name, options)
		end
	end
end
