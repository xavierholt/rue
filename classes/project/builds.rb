module Rue
	class Project
		
		def build(name, &block)
			self.task(name) do
				self.scoped do
					@build = name
					block.call if block
					self.run!('build')
				end
			end
		end
		
		def init_default_build
			@default_build = 'default'
			self.build('default')
		end
	end
end
