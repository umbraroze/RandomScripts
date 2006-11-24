a = HMS.new
b = HMS.new
a.m = 60
a.to_s
a.m = 90
a.to_s
a.m = 640
a.to_s
a.m = 640.25
a.to_s

a.s = 60
a.to_s
a.s = 65
a.to_s
a.s = 365
a.to_s
a.s = 600
a.to_s
a.s = 3600
a.to_s
a.s = 3665
a.to_s


a.hms(0,20,0)
b.hms(0,40,0)
(a + b).to_s

exit
