require 'set'
require 'time'

require_relative 'cycle'

module Rue
	class FileBase
		
		attr_reader   :name
		attr_accessor :cycle
		
		def initialize(project, name, options = {})
			@project = project
			@name    = name
			@mtime   = File.mtime(@name) rescue nil
			@deps    = Set.new
			
			@project.files.register(self)
		end
		
		def args
			return {
				:source => @source,
				:target => @name
			}
		end
		
		def build?
			if(!self.exists?)
				return true
			elsif(@dtime && (@mtime < @dtime))
				return true
			else
				return false
			end
		end
		
		def build!
			@cycle.build!
			return [@mtime, @dtime].compact.max
		end
		
		def build_deps!
			@dtime = self.depmap do |d|
				d.build! unless @cycle.include? d
			end.compact.max
			return self.build?
		end
		
		def build_self!
			builder = @project.builder(@source.class, self.class)
			default = @project[builder]
		
			if(default)
				@project.logger.info("Building #{@name}")
				@project.execute(default[:command] % default.merge(self.args))
				@mtime = Time.now
			elsif(!self.exists?)
				@project.error("No rule to build missing file \"#{@name}\".")
			end
		end
		
		def depmap(&block)
			ret = @deps.map(&block)
			ret << block.call(@source) if @source
			ret
		end
		
		def dirname
			return File.dirname(@name)
		end
		
		def each_dep
			yield @source if @source
			@deps.each {|d| yield d}
		end
		
		def exists?
			return File.exists?(@name)
		end
		
		def graphed?
			return @tarjan_i
		end
		
		def graph!(stack = [])
			return @tarjan_i if @tarjan_i
			@tarjan_i = stack.count
			stack.push(self)
			
			ra = self.depmap {|d| d.graph! stack}
			@tarjan_l = (ra << @tarjan_i).min
			
			if @tarjan_i == @tarjan_l
				cycle = Cycle.new
				loop do
					file = stack.pop
					cycle.add(file)
					file.cycle = cycle
					break if file == self
				end
			end
			
			return @tarjan_l
		end
		
		def print
			puts "   #{@name} (#{self.class})"
			if @source
				puts "      Source:"
				puts "       - #{@source.name}"
			end
			if @deps and not @deps.empty?
				puts "      Dependencies:"
				@deps.each {|dep| puts "       - #{dep.name}"}
			end
			if @gens and not @gens.empty?
				puts "      Generates:"
				@gens.each {|gen| puts "       - #{gen.name}"}
			end
		end
		
		def source=(s)
			unless @source.nil? or @source == s
				@project.error("Attempted to re-source #{@name}!\n  Old Source: #{@source}\n  New Source: #{s}")
			end
			
			@source = s
		end
		
		def to_json(*args)
			ret = {:time => @ctime.to_i}
			ret[:deps] = @deps.map(&:name) unless @deps.empty?
			ret[:gens] = @gens.map(&:name) unless @gens.empty?
			return ret.to_json(*args)
		end
		
		def to_s
			return @name
		end
	end
end
