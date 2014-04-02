require 'set'
require 'time'

module Rue
	class FileBase
		
		attr_reader :name
		
		def initialize(project, name, options = {})
			@project = project
			@name    = name
			@mtime   = File.mtime(@name) rescue nil
			@deps    = Set.new
		end
		
		def args
			return {
				:source => @source,
				:target => @name
			}
		end
		
		def build?
			if(!self.exists?)
				return true
			elsif(@dtime && (@mtime < @dtime))
				return true
			else
				return false
			end
		end
		
		def build!
			deptimes  = @deps.map(&:build!)
			deptimes << @source.build! if @source
			@dtime = deptimes.compact.max
			
			if self.build?
				builder = @project.builder(@source.class, self.class)
				default = @project[builder]
			
				if(default)
					@project.logger.info("Building #{@name}")
					@project.execute(default[:command] % default.merge(self.args))
					@mtime = Time.now
				elsif(!self.exists?)
					@project.error("No rule to build missing file \"#{@name}\".")
				end
			end
			
			return [@mtime, @dtime].compact.max
		end
		
		def dirname
			return File.dirname(@name)
		end
		
		def exists?
			return File.exists?(@name)
		end
		
		def source=(s)
			unless @source.nil? or @source == s
				@project.error("Attempted to re-source #{@name}!\n  Old Source: #{@source}\n  New Source: #{s}")
			end
			
			@source = s
		end
		
		def to_json(*args)
			return {
				:deps => @deps.map(&:name),
				:gens => @gens.map(&:name),
				:time => @ctime.to_i
			}.to_json(*args)
		end
		
		def to_s
			return @name
		end
	end
end
