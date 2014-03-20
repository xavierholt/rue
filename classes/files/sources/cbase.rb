require_relative 'base'

module Rue
	class CBase < SourceFile
		
		def initialize(project, name, options)
			super(project, name, options)
		end
		
		def check!
			deps = {}
			gens = {}
			
			File.open(@name, 'r') do |file|
				file.each_line do |line|
					if(match = line.match(/\A\s*#\s*include\s+\"([^\"]+)\"/))
						dep = File.realpath(match[1], self.dirname)
						deps[dep] = {} if dep.start_with?(@project.srcdir + '/')
					end
					
					if(line.include? 'Q_OBJECT')
						gens[@name + '.moc.cpp'] = {:source => @name}
					end
				end
			end
			
			return {
				:deps => deps,
				:gens => gens
			}
		end
	end
end
