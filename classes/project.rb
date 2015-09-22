require_relative 'filestore'
require_relative 'project/builds'
require_relative 'project/subdirs'
require_relative 'project/tasks'

require 'logger'

module Rue
	class Project
		attr_accessor :default_mode
		attr_reader   :files
		attr_accessor :logger
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
				prompt = "\e[1m\e[#{COLORIZE[severity]}m#{prompt}\e[0m"
				"#{prompt}#{msg}\n"
			end
			
			@files   = FileStore.new(self)
			@options = [{
				:target_list => {},
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
				:erb => {
					:command => '%{program} %{flags} %{source} -o %{target}',
					:program => 'rhubarb',
					:flags => ''
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
			
			self.init_default_tasks
			self.init_default_build
		end
		
		def builder(src, dst)
			FileStore::BUILDERS[[src, dst]] || FileStore::BUILDERS[[src, NilClass]]
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
		
		def scoped
			duped = {}
			@options.last.each_pair {|k, v| duped[k] = v.dup}
			@options.push(duped)
			result = yield
			@options.pop
			return result
		end
		
		def target(name, options = {}, &block)
			options[:block] = block
			self[:target_list][name] = options
		end
		
		def [] (key)
			return @options.last[key]
		end
		
		def []= (key, value)
			@options.last[key] = value
		end
	end
end
