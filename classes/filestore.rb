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
			'.erb'     => ErbFile,
			'.h'       => HFile,
			'.hpp'     => HFile,
			'.o'       => OFile,
			'.out'     => OutFile,
			'.rb'      => RbFile,
			'.s'       => SFile,
			'.so'      => SOFile
		}

		BUILDERS = {
			[CFile,     OFile]     => :c,
			[CppFile,   OFile]     => :cpp,
			[CppFile,   MocFile]   => :moc,
			[ErbFile,   NilClass]  => :erb,
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
			@ignore  = File.read('.rueignore').split(/\s*\n\s*/).compact rescue []
		end

		def add(file)
			@files[file.name] = file
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

		def ignore?(path)
			@ignore.any? do |pattern|
				File.fnmatch?("**/#{pattern}", path)
			end
		end

		def load_cache
			if File.file? '.ruecache'
				@project.logger.debug("Loading cache...")
				@cache = JSON.load(File.read('.ruecache'))
			else
				@project.logger.debug("No cache found.  All sources will be crawled.")
				@cache = {}
			end
		rescue
			@project.logger.warn("Could not load cache.  All sources will be crawled.")
			@cache = {}
		end

		def objects
			self.select {|f| f.is_a? ObjectFile}
		end

		def sources
			self.select {|f| f.is_a? SourceFile}
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
			sources = @files.select {|n, f| f.is_a? SourceFile}
			File.open('.ruecache', 'w') do |file|
				file << JSON.fast_generate(sources)
			end
		end

		def targets
			self.select {|f| f.is_a? TargetFile}
		end

		def walk(root, &block)
			Dir.glob(root + '/*') do |path|
				if self.ignore? path
					@project.logger.debug("Ignoring #{path}")
				else
					stat = self.stat(path)
					if stat.directory?
						self.walk(path, &block)
					elsif stat.file?
						file = self[path]
						yield file if file and block_given?
					end
				end
			end
		end

		def [] (path, type = nil, options = {})
			if file = @files[path]
				return file
			elsif type ||= fileclass(path)
				return type.new(@project, path, options)
			else
				@project.logger.warn("Skipping file of unknown type: #{path}")
				return nil
			end
		end
	end
end
