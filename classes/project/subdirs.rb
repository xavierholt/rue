require 'fileutils'

module Rue
  class Project

    attr_reader :srcdir
    attr_reader :dstdir

    def dstdir=(dir)
      FileUtils.mkdir_p(dir)
      @dstdir = File.realpath(dir)
    end

    def srcdir=(dir)
      @srcdir = File.realpath(dir)
    end
  end
end
