require_relative '../source'

module Rue
  class CBase < SourceFile
    def crawl!
      super
      qtfile = false
      File.open(@name, 'r') do |file|
        file.each_line do |line|
          qtfile |= line.include?('Q_OBJECT')
          if(match = line.match(/\A\s*#\s*include\s+\"([^\"]+)\"/))
            self.add_relative_dep(match[1], true)
          end
        end
      end

      if qtfile
        self.gen(@project.files["#{@name}.moc.cpp"], true)
      end
    end
  end
end
