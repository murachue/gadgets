#!/usr/bin/env ruby

# iPhoneOS 4.0 Backup decoding
#  by Murachue
#   2010.07.03-

@appd = "C:/Documents and Settings/murachue/My Documents/Application Data"
@udid = "0123456789abcdef0123456789abcdef01234567"
@path = "#{@appd}/Apple Computer/MobileSync/Backup/#{@udid}"

require 'digest/sha1'

@path = ARGV[0] if ARGV.length > 0

@mbdx = {}

open("#{@path}/manifest.mbdx", "rb") do |f|
	raise "This is not MBDX" if f.read(4) != "mbdx"

	maj = f.read(1).unpack("C")[0]
	min = f.read(1).unpack("C")[0]
	ents = f.read(4).unpack("N")[0]
	STDERR.puts "MBDX #{maj}.#{min}: #{ents} entries"

	cnt = 0
	while not f.eof
		hash = f.read(20).unpack("H40")[0]
		offs = f.read(4).unpack("N")[0]
		flag = f.read(2).unpack("n")[0]

		@mbdx[offs] = {
			:hash => hash,
			:offs => offs,
			:flag => flag,
		}
		cnt += 1
	end
	STDERR.puts "#{cnt} entries read."
end

@mbdb = []

open("#{@path}/manifest.mbdb", "rb") do |f|
	raise "This is not MBDB" if f.read(4) != "mbdb"

	maj = f.read(1).unpack("C")[0]
	min = f.read(1).unpack("C")[0]
	STDERR.puts "MBDB #{maj}.#{min}"

	cnt = 0
	while not f.eof
		item = {}

		item[:offs] = f.tell - 6	# 6 maybe header size.

		item[:dom] = f.read(f.read(2).unpack("n")[0])
		item[:file] = f.read(f.read(2).unpack("n")[0])
		n = f.read(2).unpack("n")[0]
		item[:link] = f.read(n).inspect if n != 0xFFFF
		n = f.read(2).unpack("n")[0]
		item[:sha1] = f.read(n).unpack("H*")[0] if n != 0xFFFF

		f.read(2)	# something, 0xFFFF.

		item[:flag] = f.read(2).unpack("n")[0]

		f.read(4)	# something, 0x00000000.
		item[:inode] = f.read(4).unpack("N")[0]
		item[:uid] = f.read(4).unpack("N")[0]
		item[:gid] = f.read(4).unpack("N")[0]

		item[:dt1] = f.read(4).unpack("N")[0]
		item[:dt2] = f.read(4).unpack("N")[0]
		item[:dt3] = f.read(4).unpack("N")[0]

		f.read(4)	# something, 0x00000000.
		item[:size] = f.read(4).unpack("N")[0]
		item[:mode] = f.read(2).unpack("n")[0]

		if item[:mode] & 0xFF != 0
			item[:xattr] = {}

			(0...(item[:mode] & 0xFF)).each do
				k = f.read(f.read(2).unpack("n")[0])
				v = f.read(f.read(2).unpack("n")[0])
				item[:xattr][k] = v
			end
		end

		@mbdb << item
		cnt += 1
	end
	STDERR.puts "#{cnt} entries read."
end

@lfiles = Dir.entries(@path).grep(/^[0-9a-fA-F]{40}$/)

STDERR.puts "Listing..."

puts ["!offs", "!file", "!link", "!uid", "!gid", "!size", "!mode", "!flag", "!flag", "!name", "!lfsh", "!dbsh", "!same"].join("\t")

@mbdb.each do |e|
	print "#{e[:offs]}\t"
	print "#{e[:dom]}/#{e[:file]}\t"
	if e.member? :link
		#print "=> #{e[:link]}\t"
		print "@\t"
	else
		print "\t"
	end
	#print "#{e[:inode].to_s(10).rjust(8," ")}\t"
	print "#{e[:uid].to_s(10).rjust(4," ")}\t"
	print "#{e[:gid].to_s(10).rjust(4," ")}\t"
	print "#{e[:size].to_s(10).rjust(10," ")}\t"
	print "#{e[:mode].to_s(16).rjust(4,"0")}\t"
	print "#{e[:flag].to_s(16).rjust(4," ")}\t"

	if @mbdx.member? e[:offs]
		f = @mbdx[e[:offs]]
		@mbdx.delete(e[:offs])
		print "#{f[:flag].to_s(16).rjust(4," ")}\t"
		print "#{f[:hash]}\t"

		#if File.exists? "#{@path}/#{f[:hash]}"
		if @lfiles.member? f[:hash]
			@lfiles.delete(f[:hash])
			d = nil
			open("#{@path}/#{f[:hash]}", "rb") do |f|
				d = f.read
			end
			h = Digest::SHA1.hexdigest(d)

			if e.member? :sha1
				print "#{h}\t"
				print "#{e[:sha1]}\t"
				if e[:sha1] == h
					print "="
				else
					print "!"
				end
			else
				print "#{h}\t"
				print "*\t"
				print "*"
			end
		else
			print "*\t"
			print "*\t"
			print "*"
		end
	else
		print "*\t"
		print "*\t"

		print "*\t"
		print "*\t"
		print "*"
	end

	puts
end

if @mbdx.length > 0
	STDERR.puts "Remaining hashes:"
	@mbdx.each do |e|
		STDERR.print "#{e[:hash]} "
		STDERR.print "#{e[:flag].to_s(16).rjust(4," ")} "
		STDERR.print "#{e[:offs]} "
		STDERR.puts
	end
else
	STDERR.puts "No remaining hashes."
end

if @lfiles.length > 0
	STDERR.puts "Remaining local files:"
	@lfiles.each do |e|
		STDERR.puts e
	end
else
	STDERR.puts "No remaining local files."
end

STDERR.puts "Listed."
