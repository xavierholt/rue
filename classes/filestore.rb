require_relative 'files/all'

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
			@cache = {}
			@files = {}
			@ignore = {}
			@targets = {}
		end
		
		def add(name, options = {})
			if(file = @files[name])
				@project.logger.debug("Merging  #{name}")
				
				file.merge(options)
				return file
			else
				@project.logger.debug("Adding   #{name}")
				
				type = self.file_class(name)
				@project.error("Unknown extension: #{name}") unless type
				file = type.new(@project, name, options)
				
				if(name.start_with? "#{@project.objdir}/latest/cache/")
					@targets.each_pair do |tree, target|
						if(name.start_with? tree)
							@project.logger.debug(" - Component of #{target.name}")
							target.reqs(file)
						end
					end
				end
				
				@files[name] = file
				return file
			end
		end
		
		def build!
			@targets.each_value {|target| target.crawl!}
		end
		
		def crawl(srcdir, objdir, dir = nil)
			Dir.chdir(dir || srcdir) do
				Dir.glob('*') do |file|
					name = File.realpath(file)
					if(Dir.exists?(file))
						FileUtils.mkdir_p(name.sub(srcdir, "#{objdir}/latest/cache"))
						self.crawl(srcdir, objdir, file)
					else
						self.add(name)
					end
				end
			end
		end
		
		def file_class(name, default = nil)
			FILETYPES.each_pair do |ext, type|
				return type if name.end_with? ext
			end
			
			return default
		end
		
		def load_cache(filename)
			File.open(filename, 'r') {|file| @cache = JSON.load(file.read)}
			#TODO:  Process into objects!
		end
		
		def obj(name, options = {})
			options[:type]   = :o
			options[:source] = name
			oname = name.sub("#{@project.srcdir}/", "#{@project.objdir}/latest/") << '.o'
			self.add(oname, options)
		end
		
		def print
			@files.each_pair do |k, v|
				puts k
				v.dependencies.each do |dep|
					puts " - #{dep}"
				end
				puts ''
			end
		end
		
		def save_cache(filename)
			files = @files.select {|f| !f.auto?}
			File.open(filename, 'w') {|file| file << files.to_json}
		end
		
		def target(name, options)
			cachedir = "#{@project.objdir}/latest/cache/#{options[:dir]}/"
			@project.logger.debug("Target   #{cachedir}")
			@targets[cachedir] = self.add("#{@project.objdir}/latest/#{name}", options)
		end
		
		def [] (key)
			if file = @files[key]
				return file
			elsif opts = @cache[key]
				return self.add(key, opts)
			else
				return nil
			end
		end
	end
end
