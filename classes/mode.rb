module Rue
	class Mode
		
		def initialize(project, name, block)
			@project = project
			@name    = name
			@prepare = block
		end
		
		def prepare!
			@project.logger.debug("Preparing mode \"#{@name}\"...")
			@project.logger.debug("Creating #{@project.objdir}/all/#{@name}")
			FileUtils.mkdir_p("#{@project.objdir}/all/#{@name}/cache")
			@project.logger.debug("Linking  #{@project.objdir}/latest")
			FileUtils.rm("#{@project.objdir}/latest", :force => true)
			FileUtils.ln_s("all/#{@name}", "#{@project.objdir}/latest", :force => true)
			
			@prepare.call if @prepare
		end
	end
end
