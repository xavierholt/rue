require_relative 'base'
require_relative 'directory'

module Rue
	class File < FSBase
		def initialize(project, name)
			super(project, name)
			
			dir = ::File.dirname(name)
			self.dir = @project.files[dir, Directory]
		end
		
		def args
			return {
				:source => self.source,
				:target => self.name
			}
		end
		
		def build!(force)
			if force or self.build_required?
				builder = @project.builder(self.source.class, self.class)
				if default = @project[builder]
					@project.logger.info("Building #{@name}")
					@project.execute(default[:command] % default.merge(self.args))
					@mtime = Time.now
				elsif self.mtime.nil?
					@project.error("No rule to build missing file \"#{@name}\".")
				end
				
				return true
			end
			
			return false
		end
		
		def build_required?
			if self.mtime.nil?
				return true
			elsif self.source
				return self.mtime < self.source.mtime
			else
				return false
			end
		end
		
		def crawl!
			return nil
		end
		
		def source
			return @deps.main
		end
		
		def source=(s)
			@deps.main = s
		rescue
			@project.error([
				"Attempted to re-source #{@name}!",
				"Old Source: #{@deps.main}",
				"New Source: #{s}"
			].join("\n   "))
		end
	end
end
