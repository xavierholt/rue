require_relative '../source'

module Rue
  class ErbFile < SourceFile

    def initialize(project, name, options = {})
      super(project, name, options)
      self.gen @project.files[@name.sub(/\.erb\Z/i, '')]
    end

    def crawl!
      super
      File.open(@name, 'r') do |file|
        file.each_line do |line|
          if match = line.match(/require_relative\s+['"]([^'"]+)['"]/)
            filename  = match[1]
            filename += '.rb' unless filename.end_with? '.rb'
            self.add_relative_dep(filename, true)
          end
        end
      end
    end

    def object?
      return false
    end
  end
end
