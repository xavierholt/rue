#! /usr/bin/env ruby

require 'erb'
require 'optparse'

$trim = nil
$safe = nil
parser = OptionParser.new do |args|
  args.banner = "#{$0} [options] filename"

  args.on('-l', '--ruby-lines') {$trim = "#{$trim}%"}
  args.on('-b', '--hide-both')  {$trim = "#{$trim}<>"}
  args.on('-e', '--hide-ends')  {$trim = "#{$trim}>"}
  args.on('-m', '--hide-minus') {$trim = "#{$trim}-"}

  args.on('-o', '--output <file>') do |file|
    $stdout = File.open(file, 'w')
  end

  args.on('-s', '--safe <level>') do |level|
    $safe = level.to_i
  end

  args.on('-p', '--path <path>') do |path|
    $LOAD_PATH.unshift(path)
  end
end

parser.parse!
if(ARGV.count != 1)
  $stderr.puts "Exactly one filename must be given."
  $stderr.puts parser
  exit 1
end

class Rhubarb
  def initialize(file)
    @basepath = File.absolute_path(File.dirname(file))
    @template = ERB.new(File.read(file), $safe, $trim || '%-')
    @template.filename = File.absolute_path(ARGV.first)
  end

  def require_relative(file)
    require File.absolute_path(file, @basepath)
  end

  def get_binding
    return binding
  end

  def result
    @template.result(binding)
  end

  def run
    @template.run(binding)
  end
end

rhubarb = Rhubarb.new(ARGV.first)
$stdout.write rhubarb.result
