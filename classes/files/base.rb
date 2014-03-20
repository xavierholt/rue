require 'set'

module Rue
	class FileBase
		
		attr_reader :name
		
		def initialize(project, name, options = {})
			@project = project
			@name    = name
			
			@time    = options[:time]
			@auto    = options[:auto]
			@source  = options[:source]
			@block   = options[:block]
			
			@deps    = Set.new
			@gens    = Set.new
			@reqs    = Set.new
			
			self.deps(options[:deps])
			self.gens(options[:gens])
		end
		
		def args
			return {
				:source => @source? @source.name : @reqs.to_a.join(' '),
				:target => @name
			}
		end
		
		def auto?
			return !!@auto
		end
		
		def build?
			if(!self.exists?)
				return true
			elsif(@dep_mtime && (self.mtime < @dep_mtime))
				return true
			else
				return false
			end
		end
		
		def build!
			builder = @project.builder(@source.class, self.class)
			default = @project[builder]
			
			if(default)
				@project.logger.info("Building #{@name}")
				@project.execute(default[:command] % default.merge(self.args))
			elsif(!self.exists?)
				@project.error("No rule to build missing file \"#{@name}\".")
			end
		end
		
		def check?
			return (@time.nil? || self.mtime > @time)
		end
		
		def check!
			# Run the dependency check!
		end
		
		def compiler
			return nil
		end
		
		def crawl!
			@project.logger.debug("Crawling #{@name}")
			if(@max_mtime.nil?)
				if(self.check?)
					@time = Time.now
					if(dgs = self.check!)
						self.deps(dgs[:deps])
						self.gens(dgs[:gens])
					end
				end
			
				deptimes = (@deps + @reqs).map {|dep| dep.crawl!}
				@dep_mtime = deptimes.max
			
				self.build! if self.build?
				@max_mtime = [self.mtime, @dep_mtime].compact.max
			end
			
			return @max_mtime
		end
		
		def deps(list = nil)
			list.each_pair do |name, opts|
				@deps.add(@project.file(name, opts))
			end if list
			
			return @deps
		end
		
		def dirname
			return File.dirname(@name)
		end
		
		def exists?
			return File.exists?(@name)
		end
		
		def gens(list = nil)
			list.each_pair do |name, opts|
				@gens.add(@project.file(name, opts))
			end if list
			
			return @gens
		end
		
		def merge(options)
			unless(@source.nil? or @source == options[:source])
				throw Exception.new("Attempting to re-source #{@name}.")
			end
			
			self.deps(options[:deps])
			self.gens(options[:gens])
			@source = options[:source]
		end
		
		def mtime
			File.mtime(@name) rescue nil
		end
		
		def reqs(list = nil)
			Array(list).each do |req|
				@reqs.add(req)
			end
			
			return @reqs
		end
		
		def to_json
			return {
				:auto => self.auto?,
				:deps => @deps.inject({}) {|h, d| h[d.name] = d.to_json; h},
				:gens => @gens.inject({}) {|h, g| h[g.name] = g.to_json; h},
				:time => @time
			}.to_json
		end
		
		def to_s
			return @name
		end
	end
end
