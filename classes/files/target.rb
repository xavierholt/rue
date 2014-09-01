require_relative 'file'

module Rue
	class TargetFile < File
		
		attr_reader :objdir
		attr_reader :srcdir
		
		def initialize(project, name, options)
			super(project, name)
			@srcdir = ::File.realpath(options[:srcdir])
			@objdir = options[:objdir]
			@block  = options[:block]
			@libs   = Array(options[:libs])
		end
		
		def args
			return {
				:mylibs => "-L'#{@project.objdir}/latest' #{@libs.map(&:linkname).join(' ')}",
				:source => (@deps.select {|dep| ObjectFile === dep}).join(' '),
				:target => @name
			}
		end
		
		def build!(force)
			result = nil
			@project.scoped do
				@project.logger.debug("Preparing #{@name}")
				@block.call if @block
				result = super
			end
			
			result
		end
	end
end
