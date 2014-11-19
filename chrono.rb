require 'date'
require 'pry'

module Chrono
  class Year
    def initialize y = nil
      @year = (y || ::Time.new.year).to_i

      correct if self.class == Year
    end

    def corrected?
      @corrected
    end

    def strict
      raise RangeError, "Invalid #{self.class} (should be #{to_s})" if @corrected
      self
    end

    def to_i
      @year
    end

    def to_s
      @year.to_s
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end

    def + years
      self.class.new(@year + years)
    end

    def - years
      self + -years
    end

    def month= month
      Month.new(@year, month)
    end

    protected

    def correct
      # year can't be invalid
      @corrected = false
    end

    def rev_opt_args args, len
      raise ArgumentError, "wrong number of arguments (#{args.length} for 0..#{len})" if args.length > len
      (len - args.length).times { args.unshift(nil) }
      args
    end
  end

  class Month < Year
    def initialize *args
      rev_opt_args args, 2
      y, mo = args

      super y

      @month = mo || ::Time.new.month

      correct if self.class == Month
    end

    def year
      Year.new @year
    end

    def year= y
      @year = y.to_i

      correct

      self
    end

    def to_i
      @month
    end

    def to_s
      "#{super}-%02d" % @month
    end

    def + months
      result = Date.new(@year, @month) >> months
      self.class.new(result.year, result.month)
    end

    def - months
      self + -months
    end

    def day= day
      Day.new(@year, @month, day)
    end

    protected

    def correct
      super

      Date.new(@year, @month)

      @corrected
    rescue ArgumentError
      crct = Date.new(@year, 1) >> (@month - 1)
      @year = crct.year
      @month = crct.month

      @corrected = true
    end
  end

  class Day < Month
    def initialize *args
      rev_opt_args args, 3
      y, mo, d = args
      super y, mo
      @day = (d || ::Time.new.day).to_i

      correct if self.class == Day
    end

    def month
      Month.new @year, @month
    end

    def month= m
      @month = m.to_i

      correct

      self
    end

    def to_i
      @day
    end

    def to_s
      "#{super}-%02d" % @day
    end

    def + days
      result = Date.new(@year, @month, @day) + days
      self.class.new(result.year, result.month, result.day)
    end

    def - days
      self + -days
    end

    protected

    def correct
      super

      Date.new(@year, @month, @day)

      @corrected
    rescue ArgumentError
      crct = Date.new(@year, @month, 1) + (@day - 1)
      @year = crct.year
      @month = crct.month
      @day = crct.day

      @corrected = true
    end
  end

  class Time < Day
    def initialize *args
      rev_opt_args args, 6
      y, mo, d, h, m, s = args

      super y, mo, d

      t = ::Time.new
      h ||= t.hour
      m ||= t.min
      s ||= time_sec(t)

      @seconds = hms_to_s(h, m, s)

      correct if self.class == Time
    end

    def day
      Day.new @year, @month, @day
    end

    def day= d
      @day = d.to_i

      correct

      self
    end

    def to_i
      @seconds
    end

    def to_s
      "#{super} %02d:%02d:%02f" % s_to_hms(@seconds)
    end

    def + seconds
      result = to_time + seconds

      self.class.new(result.year, result.month, result.day, result.hour, result.min, time_sec(result))
    end

    def - seconds
      self + -seconds
    end

    def to_time
      ::Time.utc(@year, @month, @day, *s_to_hms(@seconds))
    end

    private

    def hms_to_s h, m, s
      3600 * h + 60 * m + s
    end

    def s_to_hms s
      h = s.to_i / 3600
      m = (s % 3600).to_i / 60
      s %= 60
      [h, m, s]
    end

    # get seconds w/ nanoseconds from a ::Time
    def time_sec t
      t.sec + (t.nsec > 0 ? t.nsec / 1_000_000_000.0 : 0)
    end

    protected

    def correct
      super

      crct = ::Time.utc(@year, @month, @day) + @seconds

      # it's corrected if the date changed
      if [crct.year, crct.month, crct.day] != [@year, @month, @day]
        @year = crct.year
        @month = crct.month
        @day = crct.day
        @seconds = time_sec(crct)

        @corrected = true
      end

      @corrected
    end
  end
end
