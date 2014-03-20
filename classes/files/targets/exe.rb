require_relative 'base'

module Rue
	class ExeFile < FileBase
		
		def initialize(project, filename, deps)
			deps ||= @project.libs.map {|l| l.filename}
			super(project, filename, :exe, deps)
		end
	end
end
