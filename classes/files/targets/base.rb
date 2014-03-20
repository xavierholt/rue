require_relative '../base'

module Rue
	class TargetFile < FileBase
		
		def initialize(project, name, options = {})
			super(project, name, options)
			
			@libs = Set.new
			self.libs(options[:libs])
		end
		
		def args
			ret = super
			ret[:libs] = @libs.inject("-L#{@project.objdir}/latest") do |acc, lib|
				acc << " -l#{lib.name.sub(/\.[^.]*\Z/, '').sub(/\Alib/, '')}"
			end
			
			return ret
		end
		
		def build?
			b = super
			@project.logger.info("#{@name} is up to date.") unless b
			return b
		end
		
		def crawl!
			@project.scoped do
				if(@block)
					@project.logger.debug("Preparing #{@name}")
					@block.call
				end
				
				super
			end
			
			return @max_mtime
		end
		
		def filename
			return "#{self.project.objdir}/latest/#{@name}"
		end
		
		def libs(list = nil)
			#TODO: Do we really need the objects rather than the names?
			Array(list).each {|name| @libs.add(@project.file(name))}
			return @libs
		end
	end
end
