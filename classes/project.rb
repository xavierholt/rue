require_relative 'mode'
require_relative 'filestore'

require 'fileutils'
require 'logger'

module Rue
	class Project
		
		attr_accessor :default_mode
		attr_accessor :logger
		attr_reader   :objdir
		attr_reader   :srcdir
		
		def initialize
			@files  = FileStore.new(self)
			@logger = Logger.new(STDOUT)
			@modes  = {}
			
			self.objdir = 'builds'
			self.srcdir = 'src'
			
			@options = [{
				:a => {
					:command => '%{program} %{flags} %{target} %{source}',
					:program => 'ar',
					:flags => 'rcs'
				},
				:c => {
					:command => '%{program} %{flags} %{source} -o %{target}',
					:program => 'gcc',
					:flags => '-c'
				},
				:cpp => {
					:command => '%{program} %{flags} %{source} -o %{target}',
					:program => 'g++',
					:flags => '-c'
				},
				:moc => {
					:command => '%{program} %{flags} %{source} -o %{target}',
					:program => 'moc-qt4',
					:flags => ''
				},
				:o => {
					:command => '%{program} %{flags} %{source} -o %{target}',
					:program => 'ld',
					:flags => '-Ur'
				},
				:out => {
					:command => '%{program} %{flags} %{source} -o %{target} %{libs}',
					:program => 'g++',
					:flags => ''
				},
				:s => {
					:command => '%{program} %{flags} %{source} -o %{target}',
					:program => 'as',
					:flags => ''
				},
				:so => {
					:command => '%{program} %{flags} %{source} -o %{target}',
					:program => 'g++',
					:flags => '-shared'
				}
			}]
			
			self.mode('default') do
				# Nothing special.
			end
			
			self.mode('clean') do
				@logger.info("Removing #{self.objdir}")
				FileUtils.rm_rf(self.objdir)
				self[:build] = false
			end
		end
		
		def build!(*modes)
			error('Error:  No source directory.') if @srcdir.nil?
			error('Error:  No builds directory.') if @objdir.nil?
			
			modes << @default_mode if modes.empty?
			modes.each do |modename|
				@logger.info("Building mode #{modename}")
				mode = @modes[modename]
				
				if(mode.nil?)
					@logger.warn("No mode \"#{modename}\" is defined - skipping.")
					next
				end
			
				self.scoped do
					mode.prepare!
					
					unless(self[:build] == false)
						@files.crawl(@srcdir, @objdir)
						@files.build!
					end
				end
			end
		end
		
		def builder(src, dst)
			return FileStore::BUILDERS[[src, dst]]
		end
		
		def execute(command)
			@logger.debug(command)
			unless(system(command))
				error('Command failed:', command)
			end
		end
		
		def error(str, detail = nil)
			@logger.fatal(str)
			@logger.fatal(detail) if detail
			exit(1)
		end
		
		def file(name, options = {})
			@files.add(name, options)
		end
		
		def mode(name, &block)
			@default_mode ||= name
			@modes[name] = Mode.new(self, name, block)
		end
		
		def objdir=(dir)
			FileUtils.mkdir_p(dir)
			@objdir = File.realpath(dir)
		end
		
		def oname(name)
			return name.sub(@srcdir, "#{@objdir}/latest/cache") << '.o'
		end
		
		def scoped
			@options.push(@options.last.dup)
			yield
			@options.pop
		end
		
		def srcdir=(dir)
			@srcdir = File.realpath(dir)
		end
		
		def target(name, options = {}, &block)
			options[:dir] ||= name.sub(/\.[^.]+\Z/, '')
			options[:reqs]  = Array(options[:reqs]).map {|r| "#{@objdir}/latest/#{r}"}
			options[:block] = block
			@files.target(name, options)
		end
		
		def [] (key)
			return @options.last[key]
		end
		
		def []= (key, value)
			@options.last[key] = value
		end
	end
end
