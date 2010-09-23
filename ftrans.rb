#
# FileTRANSfer
#

require 'socket'

BUFSIZ = 1048576

#ruby -rsocket -e"TCPServer.open(15300){|gs|s=gs.accept;STDOUT.binmode;while b=s.read(4096);STDOUT.print b;end;s.close}"
#ruby -rsocket -e'$<.binmode;s=TCPSocket.open("murachue.ddo.jp",15200);c=0;while b=$<.read(1048576);s.write b;STDERR.print "\r#{c}";c+=1;end'

def send s
	STDIN.binmode
	c = 0
	while b = STDIN.read(BUFSIZ)
		s.write b
		c += b.length
		STDERR.print "\r#{c}"
	end
	STDERR.puts
end
def recv s
	STDOUT.binmode
	c = 0
	while b = s.read(BUFSIZ)
		STDOUT.print b
		c += b.length
		STDERR.print "\r#{c}"
	end
	STDERR.puts
end

def passive p
	TCPServer.open(p.to_i).accept
end
def active t, p
	TCPSocket.open(t, p.to_i)
end

if ARGV.length < 1
	STDERR.puts "usage: #{$0} '[BUFSIZ=buffer-size;] <send|recv> <active \"target\",port|passive port>'"
else
	eval ARGV.join(' ')
end
