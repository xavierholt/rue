require_relative 'base'

module Rue
	class Directory < FSBase
	
		def initialize(project, name, options = {})
			super(project, name, options)
			@children = Set.new
		end
		
		def build?(dtime)
			return !@project.files.stat(@name)
		end
		
		def mtime
			return nil
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
			return unless child
			@children.add(child)
			child.deps.add(self)
			child.dir = self
		end
	end
end
