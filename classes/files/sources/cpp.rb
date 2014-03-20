require_relative 'cbase'

module Rue
	class CppFile < CBase
		
		def initialize(project, name, options)
			super(project, name, options)
			@project.file(self.oname, :source => self)
		end
	end
end
