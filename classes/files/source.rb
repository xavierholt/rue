require_relative 'base'

module Rue
	class SourceFile < FSBase
		
		def initialize(project, name, options = {})
			super(project, name, options)
			self.crawl! if self.crawl?
		end
		
		def add_relative_dep(name, auto)
			begin
				name = File.realpath(name, self.dirname)
			rescue
				#TODO: This, combined with crawling files as they're encountered
				#      could be a problem.  If we allow generation of source
				#      files with, say, ERB, and parse something that requires
				#      a yet non-existant file, we crash and burn.
				@project.error("Could not locate dependency \"#{name}\"", "Required by file \"#{@name}\"")
			end
			
			file = @project.files[name]
			@deps.add(file, auto)
		end
		
		def crawl!
			@project.logger.debug("Crawling #{self}")
			@ctime = Time.now
		end
		
		def crawl?
			return false if self.mtime.nil?
			
			cache = @project.files.cache(@name)
			@ctime = Time.at(cache['time']) rescue nil
			return true if @ctime.nil? or @ctime < self.mtime
			
			(cache['deps'] || []).each do |d|
				dep = @project.files[d]
				@deps.add(dep, true)
			end
			
			(cache['gens'] || []).each do |g|
				gen = @project.files[g]
				gen.source = self
				@gens.add(gen, true)
			end
			
			return false
		end
		
		def object(target)
			name = @name.sub(target.srcdir, target.objdir) << '.o'
			file = @project.files[name, OFile]
			file.source = self
			return file
		end
		
		def to_json(*args)
			ret = {:time => @ctime.to_i}
			autodeps = @deps.autonames
			autogens = @gens.autonames
			ret['deps'] = autodeps unless autodeps.empty?
			ret['gens'] = autogens unless autogens.empty?
			return ret.to_json(*args)
		end
	end
end
