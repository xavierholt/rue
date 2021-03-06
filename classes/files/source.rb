require_relative 'base'

module Rue
  class SourceFile < FSBase

    def initialize(project, name, options = {})
      super(project, name, options)
    end

    def add_relative_dep(name, auto)
      name = File.absolute_path(name, self.dirname)
      self.dep(@project.files[name], auto)
    end

    def crawl!
      @project.logger.debug "Crawling #{self}"
      @ctime = Time.now
    end

    def crawl?
      return false unless self.exists?

      cache = @project.files.cache(@name)
      @ctime = Time.at(cache['time']) rescue nil
      return true if @ctime.nil? or @ctime < self.mtime

      (cache['deps'] || []).each do |d|
        self.dep(@project.files[d], true)
      end

      (cache['gens'] || []).each do |g|
        self.gen(@project.files[g], true)
      end

      return false
    end

    def object?
      return true
    end

    def object!(targets)
      targets.each do |target|
        next unless @name.start_with? target.srcdir
        name = @name.sub(target.srcdir, target.objdir) << '.o'
        file = @project.files[name, OFile]
        target.dep file
        self.gen file
      end
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
