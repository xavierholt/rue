require_relative 'base'

module Rue
  class TargetFile < FSBase

    attr_reader :objdir
    attr_reader :srcdir
    attr_reader :libs

    def initialize(project, name, options = {})
      super(project, name, options)
      @srcdir = File.absolute_path(options[:srcdir])
      @bindir = File.absolute_path(options[:bindir])
      @objdir = File.absolute_path(options[:objdir])
      @block  = options[:block]
      @libs   = options[:libs]
    end

    def args
      return {
        :mylibs => "-L'#{@bindir}' #{@libs.map(&:linkname).join(' ')}",
        :source => (@deps.select {|dep| ObjectFile === dep}).join(' '),
        :target => self.name
      }
    end

    def scoped
      return yield if @block.nil?
      @project.scoped do
        @project.logger.debug("Preparing #{@name}")
        @block.call
        yield
      end
    end
  end
end
