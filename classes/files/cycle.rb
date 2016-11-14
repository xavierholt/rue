module Rue
  class Cycle

    def initialize(project, stack, last)
      @project = project
      @files   = Set.new
      @deps    = Set.new
      @libs    = Set.new

      loop do
        file = stack.pop
        file.cycle = self
        @files.add(file)
        @deps.merge(file.deps.map(&:cycle).compact)
        @libs.merge(file.libs.map(&:cycle).compact)
        break if file == last
      end

      @deps.delete(self)

      if @files.count > 1
        tgt = @files.any? {|file| TargetFile === file}
        @project.logger.log(tgt ? Logger::ERROR : Logger::WARN, 'Circular dependency!')
        @files.each {|file| @project.logger.warn(" - #{file}")}
        @project.error("Aborting:  Targets may not contain cycles.") if tgt
      end
    end

    def build!
      unless @built
        @built = true
        ltimes = @libs.map(&:build!)

        @files.first.scoped do
          dtimes = @deps.map(&:build!)
          @btime = (ltimes + dtimes).compact.max
          ftimes = @files.map do |file|
            file.build! if file.build? @btime
            file.mtime
          end

          @btime = (ftimes << @btime).compact.max
        end
      end

      return @btime
    end

    def print(level = 0)
      puts "#{'   ' * level}#{self}"
      @files.each {|f| puts "#{'   ' * level}    - #{f}"} if @files.count > 1
      @deps.each {|d| d.print(level + 1)}
    end

    def to_s
      if @files.count == 1
        @files.first.to_s
      else
        "Cycle [#{@files.count} files]"
      end
    end
  end
end
