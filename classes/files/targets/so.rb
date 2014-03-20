require_relative 'base'

module Rue
	class SOFile < FileBase
		
		def initialize(project, name, options = {})
			super(project, name, options)
		end
	end
end
