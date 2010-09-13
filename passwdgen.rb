#!/usr/bin/env ruby

# symsafe  = JP/US safe
# symshift = JP/US safe and needs SHIFT key
# symother = JP/US differs

Version=0.1

require "optparse"

# opt
conf = {
	:upper    => 0,
	:lower    => 0,
	:num      => 0,
	:symsafe  => 0,
	:symshift => nil,
	:symother => nil,
	:space    => nil,
	:usrpat   => nil,
	:usrcnt   => 0,

	:length   => 8,
	:times    => 1,

	:debug    => nil,
}

opts = OptionParser.new
opts.on("-N", "--none", ""){|v|
	conf[:upper] = nil
	conf[:lower] = nil
	conf[:num] = nil
	conf[:symsafe] = nil
	conf[:symshift] = nil
	conf[:symother] = nil
	conf[:space] = nil
}
opts.on("-A", "--all", ""){|v|
	conf[:upper] = 0
	conf[:lower] = 0
	conf[:num] = 0
	conf[:symsafe] = 0
	conf[:symshift] = 0
	conf[:symother] = 0
	conf[:space] = 0
}
opts.on("-u [num]", "--upper [num]"   ){|v| conf[:upper]    = v ? v.to_i : 0}
opts.on("-l [num]", "--lower [num]"   ){|v| conf[:lower]    = v ? v.to_i : 0}
opts.on("-n [num]", "--num [num]"     ){|v| conf[:num]      = v ? v.to_i : 0}
opts.on("-s [num]", "--symsafe [num]" ){|v| conf[:symsafe]  = v ? v.to_i : 0}
opts.on("-h [num]", "--symshift [num]"){|v| conf[:symshift] = v ? u.to_i : 0}
opts.on("-o [num]", "--symother [num]"){|v| conf[:symother] = v ? v.to_i : 0}
opts.on("-S [num]", "--space [num]"   ){|v| conf[:space]    = v ? v.to_i : 0}
opts.on("-U pat", "--user pat"   ){|v| conf[:usrpat] = v}
opts.on("-C num", "--usercount num"   ){|v| conf[:usrcnt] = v.to_i}

opts.on("-L length", "--length=length", ""){|v| conf[:length] = v.to_i}
opts.on("-T times", "--times=times", ""){|v| conf[:times] = v.to_i}

opts.on("-D", "--debug", ""){|v| conf[:debug] = true}

opts.parse!(ARGV)

raise "Option error: Length less than 1" if conf[:length] < 1
raise "Option error: Times less than 1" if conf[:times] < 1

if conf[:debug] # debug
	puts "== CONFIG"
	puts "Upper    = #{conf[:upper].inspect}"
	puts "Lower    = #{conf[:lower].inspect}"
	puts "Num      = #{conf[:num].inspect}"
	puts "Symsafe  = #{conf[:symsafe].inspect}"
	puts "Symshift = #{conf[:symshift].inspect}"
	puts "Symother = #{conf[:symother].inspect}"
	puts "Space    = #{conf[:space].inspect}"
	puts "Usrpat   = #{conf[:usrpat].inspect}"
	puts "Usrcnt   = #{conf[:usrcnt].inspect}"
	puts "== END"
end

# gen
tab = ''
CUPPER    = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
CLOWER    = 'abcdefghijklmnopqrstuvwxyz'
CNUM      = '0123456789'
CSYMSAFE  = '-,./'	# '-' must be first or last, due to wd.count below.
CSYMSHIFT = '!#$%<>?'
CSYMOTHER = '"&\'()=^~\\|@`[{;+:*]}_'	# '^' must NOT be first, ditto.
CSPACE    = ' '
tab += CUPPER    if conf[:upper]
tab += CLOWER    if conf[:lower]
tab += CNUM      if conf[:num]
tab += CSYMSAFE  if conf[:symsafe]
tab += CSYMSHIFT if conf[:symshift]
tab += CSYMOTHER if conf[:symother]
tab += CSPACE    if conf[:space]
tab += conf[:usrpat] if conf[:usrpat]
if conf[:debug]
	puts "PRE: \"#{tab}\""
end
tab = tab.split(//).sort.join("").squeeze	# uniq pat
if conf[:debug]
	puts "POST: \"#{tab}\""
end

def check(s, c, g)
	return (c and (c > 0) and (s.count(g) < c))
end

guess = 0

conf[:times].times do
	wd = ''
	conf[:length].times do
		wd += tab[rand(tab.length), 1]
	end
	guess += 1
	#print "\r#{wd}"
	redo if check(wd, conf[:upper],    CUPPER)
	redo if check(wd, conf[:lower],    CLOWER)
	redo if check(wd, conf[:num],      CNUM)
	redo if check(wd, conf[:symsafe],  CSYMSAFE)
	redo if check(wd, conf[:symshift], CSYMSHIFT)
	redo if check(wd, conf[:symother], CSYMOTHER)
	redo if check(wd, conf[:space],    CSPACE)
	redo if conf[:usrpat] and conf[:usrcnt] and check(wd, conf[:usrcnt], conf[:usrpat])
	#puts "\r#{wd}"
	puts wd
end

if conf[:debug]
	puts "Stat: #{guess} guesses, #{conf[:times]} words."
end
