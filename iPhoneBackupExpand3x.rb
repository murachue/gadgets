# extract iPhone backed up files by iTunes
#  by Murachue

# TODO:
#  path divider('/' or '\')

require 'rubygems'
require 'plist'
require 'bplist'
require 'fileutils'

@cur = Dir.pwd
Dir.chdir ARGV[0] #'C:\Users\murachue\AppData\Roaming\Apple Computer\MobileSync\Backup\0123456789abcdef0123456789abcdef01234567'
#destdir = "#{@cur}/expandrb"
#destdir = "#{ARGV[0].split('\\')[0..-2].join('/')}/#{ARGV[0].split('\\').last}.expand"
destdir = "#{ARGV[0]}.expand"

#puts destdir

#exit

a = Plist::parse_xml("Manifest.plist")
#p a
b = Bplist::parse(a['Data'].string)
#b.dump
@metadata = b.tree
#Dir.chdir @cur

#x = Hash.new(0)
#b.tree["Files"].each do |k, e|
#	x[e["Domain"]] += 1
#end
#x.sort.each do |k,v|
#	puts "#{k} = #{v}"
#end
#exit

def mymkdir(p)	# XXX: no check p is file, ... that isn't directory.
	if File.exist? p
		return
	end

	begin
		Dir.mkdir p
	rescue Errno::EEXIST
		# no-op. already exist.
		return
	rescue Errno::ENOENT
		# it seems no parent path entry. (e.g. mkdir 'hoge/fuga/piyo' without 'hoge')
		pp = p.split('/')[0..-2].join('/')
		if pp == ""
			raise "FATAL: mymkdir: path become null (#{p.inspect} => #{pp.inspect})"
		end
		mymkdir(pp)	# mkdir parent.
		mymkdir(p)	# Dir.mkdir failed. retry it.
	end
end

def extract(appid, todir = "#{@cur}/#{appid}")
	#todir = "#{@cur}/#{appid}"

	# first, mkdir todir.
	mymkdir todir

	# second, copy each files.
	@metadata["Applications"][appid]["Files"].each{ |f|
		open("#{f}.mdinfo", "r"){ |g|
			h = Bplist::parse(g.binmode.read)
			path = h.tree["Metadata"]["Path"]
			#puts "#{f}.mddata = #{path}"
			print "."
			
			begin
				d = "#{todir}/#{path.split('/')[0..-2].join('/')}"	# ...makes path.(without filename)
				#p d
				mymkdir d
			rescue Errno::EEXIST
				# no-op. dir already exist.
			end

			FileUtils.copy_file("#{f}.mddata", "#{todir}/#{path}");
		}
	}
	puts
end

# extract single or...
#appid = "jp.co.infocity.BB2C10"
##appname = @metadata["Applications"][appid]["AppInfo"]["Path"].split("/").last
#extract(appid)

# extract everything(except no documents/preferences app's)
#@metadata["Applications"].each do |app|
#	print app[0]
#	if app[1]["Files"].length > 2	# iTunesArtwork and iTunesMetadata.plist are always saved.
#		extract(app[0], "#{destdir}/#{app[0]}")
#	else
#		puts " *skipped*"
#	end
#end

# extract everything by every Files
@metadata["Files"].each do |k, v|
	open("#{k}.mdinfo", "r"){ |f|
		p = Bplist::parse(f.binmode.read)
		path = p.tree["Metadata"]["Path"]
		#puts "#{f}.mddata = #{path}"
		#print "."

		begin
			d = "#{destdir}/#{v["Domain"]}/#{path.split('/')[0..-2].join('/')}"	# ...makes path.(without filename)
			#p d
			mymkdir d
		rescue Errno::EEXIST
			# no-op. dir already exist.
		end

		FileUtils.copy_file("#{k}.mddata", "#{destdir}/#{v["Domain"]}/#{path}");
		puts "#{destdir.split('\\').last}/#{v["Domain"]}/#{path}"
	}
end
