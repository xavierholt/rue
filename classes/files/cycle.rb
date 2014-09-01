module Rue
	class Cycle
		
		def initialize(stack, last)
			@files = Set.new
			@deps  = Set.new
			
			loop do
				file = stack.pop
				@files.add(file)
				file.cycle = self
				break if file == last
			end
		end
		
		def build!
			return @built unless @built.nil?
			force   = @deps.reduce(false) {|f, dep|  f |= dep.build!}
			force ||= @files.any? {|file| file.build_required?}
			@built  = @files.reduce(force) {|f, file| f |= file.build! force}
			return @built
		end
		
		def check!
			return if @checked
			@checked = true
			
			@files.each do |file|
				@deps.merge(file.deps.map(&:cycle))
			end
			
			@deps.delete(self)
		end
		
		def to_s
			if @files.count == 1
				"Cycle [#{@files.first}]"
			else
				"Cycle [#{@files.count} files]"
			end
		end
	end
end
