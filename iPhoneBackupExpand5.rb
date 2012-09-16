#!/usr/bin/env ruby

# iPhoneOS 5.1.1 backup decoding
#  by Murachue
#   2012.09.16-

@appd = ENV["appdata"]
@udid = "0123456789abcdef0123456789abcdef01234567"
@path = "#{@appd}/Apple Computer/MobileSync/Backup/#{@udid}"
@path = ARGV[0] if ARGV.length > 0

require 'digest/sha1'

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

		item[:mode] = f.read(2).unpack("n")[0]

		f.read(4)	# something, 0x00000000.
		item[:inode] = f.read(4).unpack("N")[0]
		item[:uid] = f.read(4).unpack("N")[0]
		item[:gid] = f.read(4).unpack("N")[0]

		item[:dt1] = f.read(4).unpack("N")[0]
		item[:dt2] = f.read(4).unpack("N")[0]
		item[:dt3] = f.read(4).unpack("N")[0]

		f.read(4)	# something, 0x00000000.
		item[:size] = f.read(4).unpack("N")[0]
		item[:flag] = f.read(2).unpack("n")[0]

		if item[:flag] & 0xFF != 0
			item[:xattr] = {}

			(0...(item[:flag] & 0xFF)).each do
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

puts ["!offs", "!file", "!fileSHA1", "!link", "!mode", "!inode", "!uid", "!gid", "!dt1", "!dt2", "!dt3", "!size", "!flag"].join("\t")

@mbdb.each do |e|
	print "#{e[:offs]}\t"
	print "#{e[:dom]}/#{e[:file]}\t"
	print Digest::SHA1.hexdigest("#{e[:dom]}-#{e[:file]}") + "\t"
	if e.member? :link
		#print "=> #{e[:link]}\t"
		print "@\t"
	else
		print "\t"
	end
	print "#{e[:mode].to_s(8).rjust(6,"0")}\t"
	print "#{e[:inode].to_s(10).rjust(8," ")}\t"
	print "#{e[:uid].to_s(10).rjust(4," ")}\t"
	print "#{e[:gid].to_s(10).rjust(4," ")}\t"
	print "#{Time.at(e[:dt1])}\t"
	print "#{Time.at(e[:dt2])}\t"
	print "#{Time.at(e[:dt3])}\t"
	print "#{e[:size].to_s(10).rjust(10," ")}\t"
	print "#{e[:flag].to_s(16).rjust(4," ")}\t"

	if e[:xattr] != nil
		e[:xattr].each do |k,v|
			print "#{k}=#{v.unpack("H*")[0]}\t"
		end
	end

	puts
end

STDERR.puts "Listed."
