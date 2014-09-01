require_relative '../source'

module Rue
	class ErbFile < FileBase
		
		def initialize(project, name, options)
			super(project, name, options)
			@project.file(name.sub(/\.erb\Z/i, ''), :source => self)
		end
		
		def compiler
			:erb
		end
	end
end
