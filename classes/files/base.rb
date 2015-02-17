require 'set'
require 'time'

require_relative 'cycle'
require_relative '../depset'

module Rue
	class FSBase
		
		attr_reader   :deps
		attr_accessor :dir
		attr_reader   :gens
		attr_writer   :mtime
		attr_reader   :name
		attr_accessor :cycle
		
		def initialize(project, name, options = {})
			project.logger.debug('Adding   ' + name)
			@project = project
			@name    = name
			@deps    = DepSet.new
			@gens    = DepSet.new
			
			if !options[:root] or @project.files.include? self.dirname
				@project.files[self.dirname, Directory] << self
			end
		end
		
		def args
			return {
				:source => self.source,
				:target => self.name
			}
		end
		
		def build!
			if command = self.command
				@project.logger.info("Building #{@name}")
				@project.execute(command)
				@mtime = Time.now
			elsif self.mtime.nil?
				@project.error("No rule to build missing file \"#{@name}\".")
			end
		end
		
		def build?(dtime)
			if self.mtime.nil?
				return true
			elsif dtime.nil?
				return false
			else
				return self.mtime < dtime
			end
		end
		
		def command
			builder = @project.builder(self.source.class, self.class)
			if default = @project[builder]
				return default[:command] % default.merge(self.args)
			end
		end
		
		def crawl!
			throw NotImplementedError.new
		end
		
		def crawl?
			return false
		end
		
		def dirname
			return File.dirname(@name)
		end
		
		def exists?
			return !self.mtime.nil?
		end
		
		def graph!(stack = [])
			if @tarjan_i
				return @cycle? nil : @tarjan_i
			end
			
			@tarjan_i = stack.count
			stack.push(self)
			
			ra = self.deps.map {|d| d.graph! stack}
			@tarjan_l = (ra << @tarjan_i).compact.min
			
			Cycle.new(@project, stack, self) if @tarjan_i == @tarjan_l
			return @tarjan_i
		end
		
		def libs
			return []
		end
		
		def mtime
			if @mtime
				return @mtime
			elsif @mtime.nil?
				stat = @project.files.stat(@name)
				@mtime = (stat)? stat.mtime : false
				return @mtime || nil
			else
				return nil
			end
		end
		
		def object(target)
			return nil
		end
		
		def print
			puts "\e[1m#{@name}\e[0m (#{self.class})"
			@deps.each do |dep|
				desc = case(dep)
				when @dir
					"\e[34mdir\e[39m"
				when @deps.main
					"\e[36msrc\e[39m"
				else
					"\e[35mdep\e[39m"
				end
				puts "  #{desc} #{dep.name}"
			end
			
			@gens.each do |gen|
				puts "  \e[32mgen\e[39m #{gen.name}"
			end
		end
		
		def scoped
			yield
		end
		
		def source
			return @deps.main
		end
		
		def source=(s)
			@deps.main = s
		rescue
			@project.error([
				"Attempted to re-source #{@name}!",
				"Old Source: #{@deps.main}",
				"New Source: #{s}"
			].join("\n   "))
		end
		
		def to_s
			return self.name
		end
		
		def walk(level = 0)
			yield(self, level)
		end
	end
end
