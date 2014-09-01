require_relative 'cbase'

module Rue
	class HFile < CBase
		
		def build!(force)
			return false
		end
		
		def object(target)
			# I'm just a header - don't compile me!
			return nil
		end
	end
end
