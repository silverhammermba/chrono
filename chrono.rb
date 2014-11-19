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
      y, m = args

      super y

      @month = (m || ::Time.new.month).to_i

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
      result = ::Date.new(@year, @month) >> months
      self.class.new(result.year, result.month)
    end

    def - months
      self + -months
    end

    protected

    def correct
      super

      ::Date.new(@year, @month)

      @corrected
    rescue ArgumentError
      crct = ::Date.new(@year, 1) >> (@month - 1)
      @year = crct.year
      @month = crct.month

      @corrected = true
    end
  end

  class Date < Month
    def initialize *args
      rev_opt_args args, 3
      y, m, d = args
      super y, m
      @day = (d || ::Time.new.day).to_i

      correct if self.class == Date
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
      result = ::Date.new(@year, @month, @day) + days
      self.class.new(result.year, result.month, result.day)
    end

    def - days
      self + -days
    end

    def to_date
      ::Date.new(@year, @month, @day)
    end

    protected

    def correct
      super

      ::Date.new(@year, @month, @day)

      @corrected
    rescue ArgumentError
      crct = ::Date.new(@year, @month, 1) + (@day - 1)
      @year = crct.year
      @month = crct.month
      @day = crct.day

      @corrected = true
    end
  end

  class Time < Date
    def initialize *args
      rev_opt_args args, 4
      y, m, d, s = args

      super y, m, d

      s ||= Chrono.seconds(::Time.new)

      @seconds = s

      correct if self.class == Time
    end

    def date
      Date.new @year, @month, @day
    end

    def day= d
      @day = d.to_i

      correct

      self
    end

    def to_f
      @seconds.to_f
    end

    def to_i
      to_f.to_i
    end

    def to_s
      "#{super} %02d:%02d:%02f" % Chrono.hms(@seconds)
    end

    def + seconds
      result = to_time + seconds

      self.class.new(result.year, result.month, result.day, Chrono.seconds(result))
    end

    def - seconds
      self + -seconds
    end

    def to_time
      ::Time.utc(@year, @month, @day, *Chrono.hms(@seconds))
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
        @seconds = Chrono.seconds(crct)

        @corrected = true
      end

      @corrected
    end
  end

  # convert hour, minute, seconds to seconds in the day. Or get seconds in the day from a ::Time
  def self.seconds *args
    if args.length == 1
      time = args[0]
      3600 * time.hour + 60 * time.min + t.sec + (t.nsec > 0 ? t.nsec / 1_000_000_000.0 : 0)
    elsif args.length == 3
      h, m, s = args
      3600 * h + 60 * m + s
    else
      raise ArgumentError, "wrong number of arguments (#{args.length} for 1, 3)"
    end
  end

  def self.hms seconds
    h = seconds.to_i / 3600
    m = (seconds % 3600).to_i / 60
    seconds %= 60
    [h, m, seconds]
  end
end
