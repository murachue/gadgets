# enfragment a file in FAT12
# hard to use.

open("fd1.dsk", "r+b") do |f|
	f.seek(512 * 1)
	fatbin = f.read(512 * 9)
	f.seek(512 * 19)
	rootdir = f.read(512 * 1)
	# 33 = cluster 2

	fatc = fatbin.scan(/.../m)
	fat = fatc.inject([]) do |r,i|
		r << (i[0] | ((i[1] & 0x0F) << 8))
		r << ((i[2] << 4) | ((i[1] & 0xF0) >> 4))
		r
	end

	res = [3]	# first sector
	loop do
		n = fat[res[-1]]
		break if n == 4095
		res << n
	end
	#p res
	# [3,4,5,6,7]<4,5,6,7,X> a=1(4) b=3(5) #=> [3,6,5,4,7]<6,5,7,4,X>
	(res.length - 2).times do
		a = rand(res.length - 2) + 1
		b = rand(res.length - 2) + 1
		next if a == b
		f.seek((res[a]+31)*512)
		ablk = f.read(512)
		f.seek((res[b]+31)*512)
		bblk = f.read(512)
		f.seek((res[b]+31)*512)
		f.write(ablk)
		f.seek((res[a]+31)*512)
		f.write(bblk)
		res[a], res[b] = res[b], res[a]
	end
	#p res
	(1..(res.length - 1)).each do |i|
		fat[res[i - 1]] = res[i]
	end
	fat[res[res.length - 1]] = 4095

	refatb = ""
	(0...fat.length/2).each do |i|
		a = fat[i * 2 + 0]
		b = fat[i * 2 + 1]
		c = (a & 0xFF).chr + (((a & 0xF00) >> 8) | ((b & 0xF) << 4)).chr + ((b & 0xFF0) >> 4).chr
		#p c
		refatb += c
	end
	refatb = refatb + "\x00" * (fatbin.length - refatb.length)

	f.seek(512 * 1)
	f.write(refatb)
	f.seek(512 * 10)
	f.write(refatb)
end
