require 'find'
require 'json'

module Rue
	class FileStore2
		include Enumerable
		
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
			[MocFile,  OFile]   => :cpp,
			[SFile,    OFile]   => :as,
			
			[NilClass, AFile]   => :a,
			[NilClass, OFile]   => :o,
			[NilClass, OutFile] => :out,
			[NilClass, SOFile]  => :so
		}
		
		attr_reader :targets
		
		def initialize(project)
			@project = project
			@targets = []
			
			@all  = []
			@map  = {}
			@stat = {}
			
			begin
				@project.logger.debug("Loading cache.")
				::File.open('.ruecache', 'r') do |file|
					@cache = JSON.load(file.read)
				end
			rescue
				@project.logger.warn("Failed to load cache!")
				@cache = {}
			end
		end
		
		def add(path, type = nil)
			if file = @map[path]
				return file
			elsif type ||= fileclass(path)
				file = type.new(@project, path)
				return @map[path] = file
			else
				@project.logger.warn("Skipping file of unknown type: #{path}")
				return nil
			end
		end
		
		def cache(path)
			return @cache[path]
		end
		
		def each
			@all.each {|file| yield file}
		end
		
		def fileclass(name, default = nil)
			FILETYPES.each_pair do |k, v|
				return v if name.end_with?(k)
			end
			
			return default
		end
		
		def include?(path)
			return @map.include?(path)
		end
		
		def stat(path)
			stat = @stat[path]
			if stat
				return stat
			elsif stat.nil?
				stat = ::File.stat(path) rescue false
				return @stat[path] = stat
			else
				return nil
			end
		end
		
		def save_cache
			@project.logger.debug("Saving cache.")
			sources = @map.select {|n, f| SourceFile === f}
			::File.open('.ruecache', 'w') do |file|
				file << JSON.fast_generate(sources)
			end
		end
		
		def target(name, options)
			path = "#{@project.objdir}/latest/#{name}"
			type = fileclass(name, OutFile)
			file = type.new(@project, path, options)
			@map[path] = file
			@all << file
			@targets << file
			return file
		end
		
		def walk(root)
			self[root, Directory]
			Dir.glob(root + '/*') do |path|
				stat = self.stat(path)
				if stat.directory?
					self.walk(path)
				elsif stat.file?
					self[path]
				end
			end
		end
		
		def [] (path, type = nil)
			if file = @map[path]
				return file
			elsif type ||= fileclass(path)
				file = type.new(@project, path)
				@map[path] = file
				@all << file
				return file
			else
				@project.logger.warn("Skipping file of unknown type: #{path}")
				return nil
			end
		end
	end
end
