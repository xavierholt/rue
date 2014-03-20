require_relative 'base'

module Rue
	class LibFile < FileBase
		
		def initialize(project, filename)
			super(project, filename, :lib)
		end
	end
end
