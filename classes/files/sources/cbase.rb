require_relative '../source'

module Rue
	class CBase < SourceFile
		
		def initialize(project, name)
			super(project, name)
		end
		
		def crawl!
			qtfile  = false
			dirname = ::File.dirname(@name)
			::File.open(@name, 'r') do |file|
				file.each_line do |line|
					qtfile |= line.include?('Q_OBJECT')
					if(match = line.match(/\A\s*#\s*include\s+\"([^\"]+)\"/))
						self.add_relative_dep(match[1], true)
					end
				end
			end
			
			if qtfile
				file = @project.files[@name + '.moc.cpp']
				file.source = self
				@gens.add(file, true)
			end
		end
	end
end
