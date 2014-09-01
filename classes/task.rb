module Rue
	class Task
		def initialize(project, name, subs, block)
			@project  = project
			@name     = name
			@subtasks = Array(subs)
			@block    = block
			@ran      = false
		end
		
		def ran?
			return @ran
		end
		
		def run!
			return if self.ran?
			@project.run!(*@subtasks)
			@project.logger.debug("Running task \"#{@name}\"...")
			@block.call if @block
			@ran = true
		end
	end
end
