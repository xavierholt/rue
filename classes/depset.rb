module Rue
	class DepSet
		include Enumerable
		
		attr_reader :main
		
		def initialize
			@files = {}
			@main = nil
		end
		
		def add(file, auto = false)
			@files[file] |= auto
		end
		
		def autonames
			result = []
			@files.each_pair do |file, auto|
				result << file.name if auto
			end
			
			return result
		end
		
		def each
			@files.each_key do |file|
				yield file
			end
		end
		
		def main=(file)
			if @main.nil?
				self.add(file)
				@main = file
			else
				raise "DepSet.main already specified."
			end
		end
	end
end
