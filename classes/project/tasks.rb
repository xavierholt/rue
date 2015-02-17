require 'fileutils'

module Rue
	class Task
		def initialize(project, name, subs, block)
			@project  = project
			@name     = name
			@subtasks = Array(subs)
			@block    = block
			@ran      = false
		end
		
		def ran?
			return @ran
		end
		
		def run!
			return if self.ran?
			@project.run!(*@subtasks)
			@project.logger.debug("Running task \"#{@name}\"...")
			@block.call if @block
		#	@ran = true
		end
	end
	
	class Project
		def task(name, subs = [], &block)
			@tasks[name.to_s] = Task.new(self, name, subs, block)
		end
		
		def run!(*tasknames)
			tasknames.each do |taskname|
				if task = @tasks[taskname.to_s]
					task.run!
				else
					self.error("No task \"#{taskname}\" defined.")
				end
			end
		end
		
		def init_default_tasks
			@tasks = {}
			
			self.task('configure') do
				self.dstdir = 'builds' if @dstdir.nil?
				self.srcdir = 'src' if @srcdir.nil? and Dir.exist? 'src'
				@files[self.dstdir, Directory, :root => true]
			end
			
			self.task('instantiate-targets', ['configure']) do
				#TODO: Repeat this task for every build!
				@build ||= @default_build
				def find_srcdir(name, *dirs)
					dirs.compact.each do |dir|
						segs = name.split('.')
						while segs.length > 0
							guess = "#{dir}/#{segs.join('.')}"
							return guess if Dir.exist? guess
							segs.pop
						end
					end
					self.error("Could not find source directory for target \"#{name}\"!")
				end
				
				targets = {}
				
				self[:target_list].each_pair do |name, options|
					options[:srcdir] ||= find_srcdir(name, self.srcdir, '.')
					options[:bindir]   = "#{self.dstdir}/all/#{@build}/bin"
					options[:objdir]   = "#{self.dstdir}/all/#{@build}/obj/#{name}"
					options[:libs]     = Array(options[:libs]).map {|n| targets[n]}
					
					path = "#{self.dstdir}/all/#{@build}/bin/#{name}"
					targets[name] = @files[path, @files.fileclass(name, OutFile), options]
					@files[options[:srcdir], Directory, :root => true]
				end
				
				self[:targets] = targets.values
				self[:target_list] = {}
			end
			
			self.task('build', ['graph']) do
				self[:targets].each {|target| target.cycle.build!}
				self.logger.info('Build completed.')
				
				FileUtils.rm("#{self.dstdir}/latest", :force => true)
				FileUtils.ln_s("all/#{@build}/bin", "#{self.dstdir}/latest", :force => true)
			end
			
			self.task('clean', ['configure']) do
				@logger.info("Removing #{self.dstdir}")
				FileUtils.rm_rf(self.dstdir)
			end
			
			self.task('instantiate-sources', ['instantiate-targets']) do
				self[:targets].each {|tgt| @files.walk(tgt.srcdir)}
				#TODO: Do this once, after everything is finished?
				#TODO: Do this once per build?
				@files.save_cache
			end
			
			self.task('instantiate-objects', ['instantiate-sources']) do
				self[:targets].each do |tgt|
					@files[tgt.srcdir].walk do |file|
						obj = file.object(tgt)
						tgt.deps.add(obj) if obj
					end
				end
			end
			
			self.task('cycles', ['graph']) do
				self[:targets].each do |tgt|
					tgt.cycle.print
				end
			end
			
			self.task('graph', ['instantiate-objects']) do
				@files.each {|file| file.graph!}
			end
			
			self.task('print', ['instantiate-sources']) do
				@files.each {|file| file.print}
			end
			
			self.task('symlink', ['build']) do
				FileUtils.rm("#{self.dstdir}/latest", :force => true)
				FileUtils.ln_s("all/#{@build}/bin", "#{self.dstdir}/latest", :force => true)
			end
			
			self.task('tree', ['instantiate-objects']) do
				@files.each do |file|
					file.walk do |f, level|
						n = f.name
						n = File.basename(f.to_s) unless file ==f
						puts '   ' * level + n
					end if file.dir.nil?
				end
			end
		end
	end
end
