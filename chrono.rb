require 'date'

module Chrono
  class Year
    def initialize y = nil
      @year = (y || ::Time.new.year).to_i

      correct_year
    end

    def corrected?
      @corrected
    end

    def strict
      raise ArgumentError, "Invalid #{self.class} (should be #{to_s})" if @corrected
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

    def correct_year
      # no such thing as an invalid year
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

      correct_month
    end

    def year
      Year.new @year
    end

    def year= y
      @year = y.to_i

      correct_month
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

    def correct_month
      @corrected = correct_year

      # check for correction
      begin
        Date.new(@year, @month)
      rescue ArgumentError
        correct = Date.new(@year, 1) >> (@month - 1)
        @year = correct.year
        @month = correct.month

        @corrected = true
      end

      @corrected
    end
  end

  class Day < Month
    def initialize *args
      rev_opt_args args, 3
      y, mo, d = args
      super y, mo
      @day = (d || ::Time.new.day).to_i

      correct_day
    end

    def month
      Month.new @year, @month
    end

    def month= m
      @month = m.to_i

      correct_day
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

    def correct_day
      @corrected = correct_month

      # check for correction
      begin
        Date.new(@year, @month, @day)
      rescue ArgumentError
        correct = Date.new(@year, @month, 1) + (@day - 1)
        @year = correct.year
        @month = correct.month
        @day = correct.day

        @corrected = true
      end

      @corrected
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
      s ||= t.sec + (t.nsec > 0 ? t.nsec / 1_000_000_000.0 : 0)

      @seconds = hms_to_s(h, m, s)

      correct_time
    end

    def day
      Day.new @year, @month, @day
    end

    def day= d
      @day = d.to_i

      correct_time
    end

    def to_i
      @seconds
    end

    def to_s
      "#{super} %02d:%02d:%02f" % s_to_hms(@seconds)
    end

    def + seconds
      result = to_time + seconds

      sec = result.sec
      sec += result.nsec / 1_000_000_000.0 if result.nsec > 0

      self.class.new(result.year, result.month, result.day, result.hour, result.min, sec)
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

    protected

    def correct_time
      @corrected = correct_day

      correct = ::Time.utc(@year, @month, @day) + @seconds
      # it's corrected if the date changed
      if [correct.year, correct.month, correct.day] != [@year, @month, @day]
        @year = correct.year
        @month = correct.month
        @day = correct.day
        @seconds = correct.sec + (correct.nsec > 0 ? correct.nsec / 1_000_000_000.0 : 0)

        @corrected = true
      end

      @corrected
    end
  end
end
