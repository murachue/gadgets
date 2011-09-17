#!/usr/bin/env ruby
# Unrealtournament99CD FileSystem via FUSE
#  useful if you are trying to install UT99 in Linux box.
#  (case sensitive system)

require 'fusefs'

class HelloDir
	attr_accessor :fmap
	def contents(path)
		(path[1..-1].split("/").inject(@fmap){|r,e|r[e]} || []).keys
	end
	def file?(path)
		elem = path[1..-1].split("/").inject(@fmap){|r,e|r[e]}
		return false if elem.nil?
		return elem.class == String
	end
	def directory?(path)
		elem = path[1..-1].split("/").inject(@fmap){|r,e|r[e]}
		return false if elem.nil?
		return elem.class == Hash
	end
	def size(path)
		elem = path[1..-1].split("/").inject(@fmap){|r,e|r[e]}
		return 0 if elem.nil?
		return 0 if elem.class != String
		return File.stat(elem).size
	end
	def read_file(path)
		#puts "READING #{path}"
		elem = path[1..-1].split("/").inject(@fmap){|r,e|r[e]}
		return nil if elem.nil?
		return nil if elem.class != String
		return File.read(elem)
	end
end

def addentry fmap, srcd, pfn
	rfn = "#{srcd}/#{pfn.downcase}"
	if File.exist? rfn
		apfn = pfn.split("/")
		apfn[0..-2].inject(fmap){|r,e|r[e] ||= {}; r[e]}[apfn[-1]] = rfn
	else
		puts "? file not found: #{pfn}" 
	end
end

def mkfmap srcd
	fmap = {}
	manf = "#{srcd}/system/manifest.ini"

	open(manf, "r") do |f|
		while s = f.gets
			s.chomp!
			if s =~ /^File=/
				m = s.match(/Src="?([^,)"]+)/) or raise "? illegal line: #{s}"
				pfn = m[1].gsub(/\\/, "/")
				addentry fmap, srcd, pfn
			end
		end
	end

	return fmap
end

srcd = ARGV[0]
targ = ARGV[1]

hellodir = HelloDir.new
hellodir.fmap = mkfmap(srcd)
addentry hellodir.fmap, srcd, "System/UNREALTOURNAMENT.EXE" # need for setup :(

FuseFS.set_root( hellodir )
# Mount under a directory given on the command line.
Dir.mkdir(targ) rescue Errno::EEXIST
FuseFS.mount_under targ
FuseFS.run
