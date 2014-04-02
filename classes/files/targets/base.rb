require_relative '../base'
require 'find'

module Rue
	class TargetFile < FileBase
		
		attr_reader :objdir
		attr_reader :srcdir
		
		def initialize(project, name, options)
			super(project, name, options)
			@block = options[:block]
			@libs  = Array(options[:libs])
			
			@objdir = options[:objdir]
			@srcdir = File.realpath(options[:srcdir])
		end
		
		def args
			return {
				:libs => "#{@project[:libs]} -L'#{@project.objdir}/latest' #{@libs.map(&:linkname).join(' ')}",
				:source => @deps.to_a.join(' '),
				:target => @name
			}
		end
		
		def build?
			b = super
			@project.logger.info("#{@name} is up to date.") unless b
			return b
		end
		
		def build!
			Find.find(@srcdir) do |path|
				if Dir.exists? path
					FileUtils.mkdir_p(path.sub(@srcdir, @objdir))
				end
			end
			
			@project.files.sources(self.srcdir).each do |s|
				o = s.object(self)
				@deps.add(o) if o
			end
			
			@project.scoped do
				@project.logger.debug("Preparing #{@name}")
				@block.call if @block
				super
			end
		end
	end
end
