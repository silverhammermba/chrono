require 'date'

module Chrono
  class Year
    # create the specified year, or use the current year if nil
    def initialize y = nil
      @year = y || ::Time.new.year
      raise TypeError, "invalid year #{@year.inspect}" unless @year.is_a? Integer

      if self.class == Year
        correct
        @date = ::Date.new(@year)
      end
    end

    def corrected?
      @corrected
    end

    # raise an error if the initialize arguments did not represent a valid point in time
    def strict
      raise RangeError, "Invalid #{self.class} (should be #{to_s})" if @corrected
      self
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end

    # convert to Ruby's built-in Date
    def as_date
      @date.dup
    end

    def year
      as_date.year
    end

    def to_s
      year.to_s
    end

    def + years
      Year.new(year + years)
    end

    def - years
      return year - years.year if years.is_a? Year
      self + -years
    end

    def strftime fmt
      # TODO
    end

    protected

    def correct
      # year can't be invalid
      @corrected = false
    end

    # require "len" optional arguments, where *leading* args are assumed to be nil
    # This is so we can easily do Chrono::Month.new(12) and fill in the current year
    def rev_opt_args args, len
      raise ArgumentError, "wrong number of arguments (#{args.length} for 0..#{len})" if args.length > len
      (len - args.length).times { args.unshift(nil) }
      args
    end
  end

  class Month < Year
    def initialize *args
      rev_opt_args args, 2
      y, m = args

      super y

      @month = m || ::Time.new.month
      raise TypeError, "invalid month #{@month.inspect}" unless @month.is_a? Integer

      if self.class == Month
        correct
        @date = ::Date.new(@year, @month)
      end
    end

    def to_year
      Year.new as_date.year
    end

    def month
      as_date.month
    end

    def to_s
      "#{super}-%02d" % month
    end

    def name
      ::Date::MONTHNAMES[month]
    end

    def + months
      result = as_date >> months
      Month.new(result.year, result.month)
    end

    def - months
      if months.is_a? Month
        return (year - months.year) * 12 + month - months.month
      end
      self + -months
    end

    protected

    def correct
      super

      d = ::Date.new(@year, 1) >> (@month - 1)

      @corrected = @corrected || !(@year == d.year && @month == d.month)

      @year = d.year
      @month = d.month
    end
  end

  class Date < Month
    def initialize *args
      rev_opt_args args, 3
      y, m, d = args

      super y, m

      @day = d || ::Time.new.day
      raise TypeError, "invalid day #{@day.inspect}" unless @day.is_a? Integer

      if self.class == Date
        correct
        @date = ::Date.new(@year, @month, @day)
      end
    end

    def to_month
      Month.new as_date.year, as_date.month
    end

    def day
      as_date.day
    end

    def to_s
      "#{super}-%02d" % day
    end

    def + days
      result = as_date + days
      Date.new(result.year, result.month, result.day)
    end

    def - days
      return (as_date - days.as_date).to_i if days.is_a? Date
      self + -days
    end

    protected

    def correct
      super

      d = ::Date.new(@year, @month, 1) + (@day - 1)

      @corrected = @corrected || !(@year == d.year && @month == d.month && @day == d.day)

      @year = d.year
      @month = d.month
      @day = d.day
    end
  end

  class Time < Date
    def initialize *args
      org_length = args.length
      rev_opt_args args, 6
      y, m, d, h, i, s = args

      # default values for HH:MM:SS are reversed
      if org_length == 2
        h = i
        i = s
        s = nil
      elsif org_length == 1
        h = s
        s = nil
      end

      super y, m, d

      t = ::Time.new
      @hour = h || t.hour
      @min = i || t.min
      @sec = s || Chrono.duck_sec(t)
      raise TypeError, "invalid hour #{@hour.inspect}" unless @hour.is_a? Integer
      raise TypeError, "invalid minute #{@min.inspect}" unless @min.is_a? Integer
      # TODO better way to handle fractional seconds
      raise TypeError, "invalid second #{@sec.inspect}" unless @sec.is_a?(Integer) || @sec.is_a?(Float)

      if self.class == Time
        correct
        @time = ::Time.utc(@year, @month, @day, @hour, @min, @sec)
      end
    end

    # convert to Ruby's built-in Time
    def as_time
      @time.dup
    end

    def as_date
      as_time.to_date
    end

    def hour
      as_time.hour
    end

    def minute
      as_time.min
    end

    def second
      Chrono.duck_sec as_time
    end

    def to_s zone = nil
      t = as_time
      t = t.getlocal(zone) if zone
      t.strftime "%Y-%m-%d %H:%M:%S"
    end

    def + seconds
      result = as_time + seconds

      t = Time.new
      t.instance_eval { @time = result }
    end

    def - seconds
      return as_time - seconds.as_time if seconds.is_a? Time
      self + -seconds
    end

    protected

    def correct
      super

      crct = ::Time.utc(@year, @month, @day) + @hour * 3600 + @min * 60 + @sec

      if [crct.year, crct.month, crct.day, crct.hour, crct.min, Chrono.duck_sec(crct)] != [@year, @month, @day, @hour, @min, @sec]
        @year = crct.year
        @month = crct.month
        @day = crct.day
        @hour = crct.hour
        @min = crct.min
        @sec = Chrono.duck_sec crct

        @corrected = true
      end

      @corrected
    end
  end

  # get seconds from a Time object, accounting for nanoseconds
  def self.duck_sec t
    return t.sec if t.nsec == 0
    t.sec + t.nsec / (10 ** 9).to_f
  end
end
