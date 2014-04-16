require_relative 'mode'
require_relative 'filestore'

require 'fileutils'
require 'logger'

module Rue
	class Project
		
		attr_accessor :default_mode
		attr_reader   :files
		attr_accessor :logger
		attr_reader   :objdir
		attr_reader   :srcdir
		
		COLORIZE = {
			'DEBUG' => 37,
			'INFO'  => 34,
			'WARN'  => 33,
			'ERROR' => 31,
			'FATAL' => 31
		}
		
		def initialize
			@logger = Logger.new(STDOUT)
			@logger.level = Logger::INFO
			@logger.formatter = proc do |severity, datetime, progname, msg|
				prompt = sprintf('%-5s (Rue): ', severity)
				prompt = "\033[1m\033[#{COLORIZE[severity]}m#{prompt}\033[0m"
				"#{prompt}#{msg}\n"
			end
			
			self.srcdir = 'src'
			self.objdir = 'builds'
			
			@files   = FileStore.new(self)
			@modes   = {}
			@options = [{
				:build => true,
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
					:command => '%{program} %{flags} %{source} -o %{target} %{mylibs} %{libs}',
					:program => 'g++',
					:flags => '',
					:libs => ''
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
			
			self.mode('print') do
				self[:build] = false
				@files.crawl!
				@files.print
			end
		end
		
		def build!(*modes)
			modes << @default_mode if modes.empty?
			modes.each do |modename|
				mode = @modes[modename]
				
				if(mode.nil?)
					@logger.warn("No mode \"#{modename}\" is defined - skipping.")
					next
				end
				
				self.scoped do
					mode.prepare!
					@files.build! if self[:build]
				end
			end
			
		ensure
			@files.save_cache if @files.crawled?
		end
		
		def builder(src, dst)
			return FileStore::BUILDERS[[src, dst]]
		end
		
		def execute(command)
			if(system(command))
				@logger.debug(command)
			else
				error('Command failed:', command)
			end
		end
		
		def error(str, detail = nil)
			@logger.fatal(str)
			@logger.fatal(detail) if detail
			exit(1)
		end
		
		def mode(name, &block)
			@default_mode ||= name
			@modes[name] = Mode.new(self, name, block)
		end
		
		def objdir=(dir)
			FileUtils.mkdir_p(dir)
			@objdir = File.realpath(dir)
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
			options[:srcdir] ||= "#{@srcdir}/#{name.sub(/\.[^.]+\Z/, '')}"
			options[:objdir] ||= "#{@objdir}/latest/cache/#{name}"
			options[:block]    = block
			options[:libs]     = Array(options[:libs]).map {|n| @files.target(n)}
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
