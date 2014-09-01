require_relative '../object'

module Rue
	class OFile < ObjectFile
		def linkname
			return @name
		end
	end
end
