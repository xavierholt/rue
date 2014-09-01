require_relative 'base'

module Rue
	class Directory < FSBase
		def initialize(project, name)
			super(project, name)
			@children = Set.new
			
			dir = ::File.dirname(@name)
			if @project.files.include?(dir)
				self.dir = @project.files[dir]
			end
		end
		
		def build!(force)
			if force or self.build_required?
				@project.logger.info("Building #{@name}")
				FileUtils.mkdir_p(@name)
			end
		end
		
		def walk(level = 0)
			yield(self, level)
			@children.each do |child|
				child.walk(level + 1) do |c, l| 
					yield(c, l)
				end
			end
		end
		
		def << (child)
			@children.add(child)
		end
	end
end
