#!/usr/bin/ruby

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/packagetask'

Rake::TestTask.new do |t|
  t.test_files = FileList.new 'test/test*.rb'
end

Rake::PackageTask.new(:sma, :noversion) do |pt|
  pt.need_tar_gz = true
  pt.version = :noversion
  pt.name = "Social Media Analysis"
  pt.package_files = FileList.new(["./*", "test/*"])
end
