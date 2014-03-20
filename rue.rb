#! /usr/bin/ruby

require_relative 'classes/project'

module Rue
	def self.project
		project = Project.new
		yield(project)
		
		project.build!(*ARGV)
	end
end

load 'ruefile'

