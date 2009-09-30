#!/usr/bin/ruby
# Project "time math sucks, so it's better to just do it once. Not sure if
# I'll do it properly, but I do it."

class HMS
  def HMS.time(h,m,s)
    a = HMS.new
    a.hms(h,m,s)
    return a
  end
  def initialize
    @h = 0
    @m = 0
    @s = 0
  end
  def h=(h)
    @h = h
    @m = 0
    @s = 0
  end
  def m=(m)
    min = m.floor
    secfrac = m - min
    sec = (secfrac * 60).floor

    @s = sec
    @m = min % 60
    @h = (min / 60)
    true
  end
  def s=(s)
    cs = s
    @s = cs % 60
    cs -= @s
    @m = (cs / 60) % 60
    cs -= @m * 60
    @h = cs / (60*60)
    true
  end
  def hms(h,m,s)
    @h = h
    @m = m
    @s = s
    true
  end
  def as_h
    @h + (@m.to_f/60) + (@s.to_f/60/60)
  end
  def as_m
    (@h*60) + @m + (@s.to_f/60)
  end
  def as_s
    (@h*60)*60 + @m*60 + @s
  end
  def to_s
    "#{@h}h #{@m}m #{@s}s"
  end

  def +(b)
    as = self.as_s
    bs = b.as_s
    self.s = as + bs
    return self
  end
  def -(b)
    as = self.as_s
    bs = b.as_s
    self.s = as - bs
    return self
  end
end
