require_relative 'base'

module Rue
	class SFile < SourceFile
		
		def initialize(project, name, options = {})
			super(project, name, options)
			@project.file(self.oname, :source => self)
		end
	end
end
