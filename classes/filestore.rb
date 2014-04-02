require_relative 'files/all'

require 'json'

module Rue
	class FileStore
		
		FILETYPES = {
			'.moc.cpp' => MocFile,
			'.a'       => AFile,
			'.c'       => CFile,
			'.cc'      => CppFile,
			'.cpp'     => CppFile,
			'.cxx'     => CppFile,
			'.h'       => HFile,
			'.hpp'     => HFile,
			'.o'       => OFile,
			'.out'     => OutFile,
			'.s'       => SFile,
			'.so'      => SOFile
		}
		
		BUILDERS = {
			[CFile,    OFile]   => :c,
			[CppFile,  OFile]   => :cpp,
			[CppFile,  MocFile] => :moc,
			[HFile,    MocFile] => :moc,
			[SFile,    OFile]   => :as,
			
			[NilClass, AFile]   => :a,
			[NilClass, OFile]   => :o,
			[NilClass, OutFile] => :out,
			[NilClass, SOFile]  => :so
		}
		
		def initialize(project)
			@project = project
			@ignore = {}
			
			@objects = {}
			@sources = {}
			@srcdirs = {}
			@targets = {}
			
			begin
				@project.logger.debug("Loading cache.")
				File.open('.ruecache', 'r') do |file|
					@cache = JSON.load(file.read)
				end
			rescue
				@project.logger.warn("Failed to load cache!")
				@cache = {}
			end
		end
		
		def build!
			@targets.each_value(&:build!)
		end
		
		def file_class(name)
			FILETYPES.each {|k, v| return v if name.end_with? k}
			return nil
		end
		
		def object(name)
			unless @objects[name]
				@objects[name] = OFile.new(@project, name)
			end
			
			return @objects[name]
		end
		
		def print
			@sources.each_pair do |k, v|
				puts k
				v.deps.each {|dep| puts " - #{dep}"}
				puts ''
			end
		end
		
		def save_cache
			@project.logger.debug("Saving cache.")
			File.open('.ruecache', 'w') do |file|
				file << JSON.fast_generate(@sources, :indent => '  ', :object_nl => "\n")
			end
		end
		
		def source(name)
			unless @sources[name]
				unless type = self.file_class(name)
					@project.logger.warn("Skipping #{name} - unknown extension.")
					return
				end
				
				@project.logger.debug("Adding   #{name}")
				file = type.new(@project, name, @cache[name] || {})
				@sources[name] = file
			end
			
			return @sources[name]
		end
		
		def sources(dir)
			dir = File.realpath(dir)
			unless @srcdirs[dir]
				@srcdirs[dir] = []
				Find.find(dir) do |path|
					unless Dir.exists? path
						name = File.realpath(path)
						file = self.source(name)
						@srcdirs[dir] << file if file
					end
				end
			end
			
			return @srcdirs[dir] || []
		end
		
		def target(name, options = {})
			unless @targets[name]
				unless type = self.file_class(options[:type] || name)
					@project.error("Could not determine type of target \"#{name}\"!")
				end
				
				fullname = "#{@project.objdir}/latest/#{name}"
				@project.logger.debug("Target   #{fullname}")
				@targets[name] = type.new(@project, fullname, options)
			end
			
			return @targets[name]
		end
	end
end
