module Rue
	class Cycle < Set
		
		def build!
			return if @built
			@built = true
			
			build = false	
			self.each {|file| build |= file.build_deps!}
			self.each {|file| file.build_self!} if build
		end
	end
end
