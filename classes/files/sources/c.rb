require_relative 'cbase'

module Rue
	class CFile < CBase
		def initialize(project, name, options)
			super(project, name, options)
			@project.file(self.oname, :source => self)
		end
	end
end
