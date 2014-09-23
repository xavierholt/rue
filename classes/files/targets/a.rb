require_relative '../target'

module Rue
	class AFile < TargetFile
		
		def linkname
			return @name
		end
	end
end
