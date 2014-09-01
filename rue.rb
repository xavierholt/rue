#! /usr/bin/ruby

require_relative 'classes/project'

module Rue
	def self.project
		project = Project.new
		yield(project)
		
		args = (ARGV.empty?)? ['build'] : ARGV
		project.run!(*args)
	end
end

load 'ruefile'

