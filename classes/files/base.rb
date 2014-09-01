require 'set'
require 'time'

require_relative 'cycle'
require_relative '../depset'

module Rue
	class FSBase
		
		attr_reader   :deps
		attr_reader   :dir
		attr_reader   :gens
		attr_reader   :name
		attr_accessor :cycle
		
		def initialize(project, name, options = {})
			project.logger.debug('Adding   ' + name)
			@project = project
			@name    = name
			
			@deps = DepSet.new
			@gens = DepSet.new
		end
		
		def build!(force)
			return false
		end
		
		def build_required?
			return self.mtime.nil?
		end
		
		def check!
			return nil
		end
		
		def dir=(file)
			@deps.add(file)
			@dir = file
			@dir << self
		end
		
		def exists?
			return !self.mtime.nil?
		end
		
		def graph!(stack = [])
			return @tarjan_i if @tarjan_i
			@tarjan_i = stack.count
			stack.push(self)
			
			ra = self.deps.map {|d| d.graph! stack}
			@tarjan_l = (ra << @tarjan_i).min
			
			Cycle.new(stack, self) if @tarjan_i == @tarjan_l
			return @tarjan_l
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
			puts "#{@name} (#{self.class})"
			@deps.each do |dep|
				desc = "\e[35m-\e[39m"
				desc = "\e[34m~\e[39m" if dep == @dir
				desc = "\e[36m*\e[39m" if dep == @deps.main
				puts "   #{desc} #{dep.name}"
			end if @deps
			
			@gens.each do |gen|
				puts "   \e[32m+\e[39m #{gen.name}"
			end if @gens
		end
		
		def to_s
			return @name
		end
		
		def walk(level = 0)
			yield(self, level)
		end
	end
end
