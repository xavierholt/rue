require_relative 'file'

module Rue
	class SourceFile < File
		def check!
			if c = @project.files.cache(@name)
				@ctime = Time.at(c['time']) rescue nil
			end
			
			if self.crawl_required?
				@project.logger.debug("Crawling #{self}")
				@ctime = Time.now
				self.crawl!
			elsif @ctime
				@project.logger.debug("Cached   #{self}")
				(c['deps']|| []).each do |d|
					dep = @project.files[d]
					@deps.add(dep, true)
				end
				
				(c['gens'] || []).each do |g|
					gen = @project.files[g]
					gen.source = self
					@gens.add(gen, true)
				end
			end
		end
		
		def crawl_required?
			if self.mtime.nil?
				return false
			elsif @ctime.nil?
				return true
			else
				return @ctime < self.mtime
			end
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
