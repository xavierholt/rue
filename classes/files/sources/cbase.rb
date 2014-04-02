require_relative 'base'

module Rue
	class CBase < SourceFile
		
		def initialize(project, name, options)
			super(project, name, options)
		end
		
		def check!
			@ctime = Time.now
			File.open(@name, 'r') do |file|
				file.each_line do |line|
					if(match = line.match(/\A\s*#\s*include\s+\"([^\"]+)\"/))
						name = File.realpath(match[1], self.dirname)
						if name.start_with?(@project.srcdir + '/')
							file = @project.files.source(name)
							@deps.add(file)
						end
					end
					
					if(line.include? 'Q_OBJECT')
						file = @project.files.source(@name + '.moc.cpp')
						file.source = self
						@gens.add(file)
					end
				end
			end
		end
	end
end
