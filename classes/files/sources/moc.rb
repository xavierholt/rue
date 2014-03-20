require_relative 'cpp'

module Rue
	class MocFile < CppFile
		
		def initialize(project, name, options)
			super(project, name, options)
		end
	end
end
