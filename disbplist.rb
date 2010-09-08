require 'bplist.rb'

open ARGV[0], "rb" do |f|
	Bplist::parse(f.read).dump
end
