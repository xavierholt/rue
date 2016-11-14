require 'set'
require 'time'

require_relative 'cycle'
require_relative '../depset'

module Rue
  class FSBase

    attr_accessor :cycle
    attr_reader   :deps
    attr_reader   :gens
    attr_reader   :name
    attr_reader   :refs

    def initialize(project, name, options = {})
      name = File.absolute_path(name)
      project.logger.debug("Adding   #{name}")

      @project = project
      @name    = name
      @deps    = DepSet.new
      @gens    = DepSet.new
      @refs    = Set.new

      project.files.add(self)
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
        FileUtils.mkdir_p(self.dirname) if self.mtime.nil?
        @project.execute(command)
        @mtime = Time.now
      elsif self.mtime.nil?
        @project.error(
          "No rule to build missing file \"#{@name}\".",
          "Required by:\n - " + @refs.to_a.join("\n - ")
        )
      end
    end

    def build?(dtime)
      if !self.exists?
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

    def dep(file, auto = false)
      @deps.add(file, auto)
      file.refs.add(self)
    end

    def dirname
      return File.dirname(@name)
    end

    def exists?
      return !self.mtime.nil?
    end

    def gen(file, auto = false)
      @gens.add(file, auto)
      file.source = self
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

    def print
      puts "\e[1m#{@name}\e[0m (#{self.class})"
      @deps.each do |dep|
        desc = case(dep)
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

      @refs.each do |ref|
        puts "  \e[30mref\e[39m #{ref.name}"
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
