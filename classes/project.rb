require_relative 'mode'
require_relative 'filestore'
require_relative 'task'

require 'fileutils'
require 'logger'

module Rue
	class Project
		attr_accessor :default_mode
		attr_reader   :files
		attr_accessor :logger
		attr_reader   :objdir
		attr_reader   :srcdir
		attr_reader   :tasks
		
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
			
			@default_mode = 'default'
			@files   = FileStore.new(self)
			@modes   = {}
			@tasks   = {}
			@options = [{
				:a => {
					:command => '%{program} %{flags} %{target} %{source}',
					:program => 'ar',
					:flags => 'rcs'
				},
				:as => {
					:command => '%{program} %{flags} %{source} -o %{target}',
					:program => 'as',
					:flags => ''
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
					:program => 'moc',
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
				:so => {
					:command => '%{program} %{flags} %{source} -o %{target}',
					:program => 'g++',
					:flags => '-shared'
				}
			}]
			
			self.mode('default')
			
			self.task('build', ['graph']) do
				built = @files.targets.inject(false) do |f, tgt|
					f |= tgt.cycle.build!
				end
				
				unless built
					self.logger.info('All targets up to date.')
				end
			end
			
			self.task('clean') do
				@logger.info("Removing #{self.objdir}")
				FileUtils.rm_rf(self.objdir)
			end
			
			self.task('crawl', ['mode']) do
				@files.targets.each do |tgt|
					@files.walk(tgt.srcdir)
				end
				
				@files.each do |file|
					file.check!
				end
				
				@files.targets.each do |tgt|
					@files[tgt.srcdir].walk do |file|
						obj = file.object(tgt)
						tgt.deps.add(obj) if obj
					end
				end
				
				@files.save_cache
			end
			
			self.task('graph', ['crawl']) do
				cycles = @files.map do |file|
					file.graph!
					file.cycle
				end
				
				cycles.each do |cycle|
					cycle.check!
				end
			end
			
			self.task('mode') do
				modename = @current_mode || @default_mode
				if mode = @modes[modename]
					mode.prepare!
				else
					self.error("No mode \"#{modename}\" defined.")
				end
			end
			
			self.task('print', ['crawl']) do
				@files.each do |file|
					file.print
				end
			end
			
			self.task('tree', ['crawl']) do
				@files.each do |file|
					file.walk do |f, level|
						n = f.name
						n = ::File.basename(f.to_s) unless file ==f
						puts '   ' * level + n
					end if file.dir.nil?
				end
			end
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
			@modes[name] = Mode.new(self, name, block)
			self.task(name) do
				self.mode = name
				self.run!('build')
			end
		end
		
		def mode=(modename)
			@current_mode = modename
		end
		
		def objdir=(dir)
			FileUtils.mkdir_p(dir)
			@objdir = ::File.realpath(dir)
		end
		
		def run!(*tasknames)
			tasknames.each do |taskname|
				if task = @tasks[taskname]
					self.scoped {task.run!}
				else
					self.error("No task \"#{taskname}\" defined.")
				end
			end
		end
		
		def scoped
			@options.push(@options.last.dup)
			yield
			@options.pop
		end
		
		def srcdir=(dir)
			@srcdir = ::File.realpath(dir)
		end
		
		def target(name, options = {}, &block)
			options[:srcdir] ||= "#{@srcdir}/#{name.sub(/\.[^.]+\Z/, '')}"
			options[:objdir]   = "#{@objdir}/latest/cache/#{name}"
			options[:block]    = block
			options[:libs]     = Array(options[:libs]).map {|n| @files.target(n)}
			@files.target(name, options)
		end
		
		def task(name, subs = [], &block)
			@tasks[name] = Task.new(self, name, subs, block)
		end
		
		def [] (key)
			return @options.last[key]
		end
		
		def []= (key, value)
			@options.last[key] = value
		end
	end
end
