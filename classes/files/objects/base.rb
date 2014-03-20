require_relative '../base'

module Rue
	class ObjectFile < FileBase
		
		def filename
			#TODO: Target-specific object directories
			return "#{self.project.objdir}/latest/cache/./#{@name}"
		end
	end
end
