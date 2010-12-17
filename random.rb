lis=ARGV.length > 0 ? ARGV : ["A","B","C"]
(0...lis.length-1).each do |i|
	j = rand(lis.length-i)+i
	lis[i],lis[j] = lis[j],lis[i]
end
puts lis.join(",")
