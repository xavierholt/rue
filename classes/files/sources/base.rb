require_relative '../base'

module Rue
	class SourceFile < FileBase
		
		def initialize(project, name, options = {})
			super(project, name, options)
			
			@ctime   = Time.at(options['time']) rescue nil
			if self.check?
				@gens = Set.new
				@project.logger.debug("Scanning #{@name}")
				self.check!
			else
				@project.logger.debug("Cached   #{@name}")
				@deps.merge(options['deps'].map do |d|
					@project.files.source(d)
				end)
				
				@gens = Set.new(options['gens'].map do |g|
					gen = @project.files.source(g)
					gen.source = self
					gen
				end)
			end
		end
		
		def check?
			return (@ctime.nil? || @mtime > @ctime)
		end
		
		def object(target)
			name = @name.sub(target.srcdir, target.objdir) << '.o'
			file = @project.files.object(name)
			file.source = self
			return file
		end
	end
end
