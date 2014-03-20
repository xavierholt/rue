require_relative '../base'

module Rue
	class SourceFile < FileBase
		
		def initialize(project, name, options = {})
			super(project, name, options)
		end
		
		def oname
			return @name.sub(@project.srcdir, "#{@project.objdir}/latest/cache") << '.o'
		end
	end
end
