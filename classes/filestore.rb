require_relative 'files/all'

require 'json'

module Rue
	class FileStore
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
			[CFile,     OFile]     => :c,
			[CppFile,   OFile]     => :cpp,
			[CppFile,   MocFile]   => :moc,
			[NilClass,  Directory] => :dir,
			[HFile,     MocFile]   => :moc,
			[MocFile,   OFile]     => :cpp,
			[SFile,     OFile]     => :as,
			
			[NilClass,  AFile]     => :a,
			[NilClass,  OFile]     => :o,
			[NilClass,  OutFile]   => :out,
			[NilClass,  SOFile]    => :so
		}
		
		attr_reader :targets
		
		def initialize(project)
			@project = project
			@files   = {}
			@stats   = {}
		end
		
		def add(path, type = nil)
			if file = @files[path]
				return file
			elsif type ||= fileclass(path)
				file = type.new(@project, path)
				return @files[path] = file
			else
				@project.logger.warn("Skipping file of unknown type: #{path}")
				return nil
			end
		end
		
		def cache(path)
			load_cache if @cache.nil?
			return @cache[path]
		end
		
		def each
			@files.each_value {|file| yield file}
		end
		
		def fileclass(name, default = nil)
			FILETYPES.each_pair do |k, v|
				return v if name.end_with?(k)
			end
			
			return default
		end
		
		def include?(path)
			return @files.include?(path)
		end
		
		def load_cache
			@project.logger.debug("Loading cache...")
			file = File.open('.ruecache', 'r')
			@cache = JSON.load(file.read) rescue @project.logger.warn("Cache corrupted!") && {}
			file.close
		rescue
			@project.logger.info("Could not load cache: all sources will be crawled.")
			@cache = {}
		end
		
		def stat(path)
			stat = @stats[path]
			if stat
				return stat
			elsif stat.nil?
				stat = File.stat(path) rescue false
				return @stats[path] = stat
			else
				return nil
			end
		end
		
		def save_cache
			@project.logger.debug("Saving cache...")
			sources = @files.select {|n, f| SourceFile === f}
			File.open('.ruecache', 'w') do |file|
				file << JSON.fast_generate(sources)
			end
		end
		
		def walk(root)
			dir = self[root, Directory]
			Dir.glob(root + '/*') do |path|
				stat = self.stat(path)
				if stat.directory?
					dir << self.walk(path)
				elsif stat.file?
					dir << self[path]
				end
			end
			dir
		end
		
		def [] (path, type = nil, options = {})
			if file = @files[path]
				return file
			elsif type ||= fileclass(path)
				file = type.new(@project, path, options)
				return @files[path] = file
			else
				@project.logger.warn("Skipping file of unknown type: #{path}")
				return nil
			end
		end
	end
end
