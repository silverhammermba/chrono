require './chrono'
require 'minitest/autorun'

describe Chrono::Year do
  it "must complain about non-integer years" do
    proc { Chrono::Year.new("2015") }.must_raise TypeError
  end

  it "must know the current year" do
    year = Chrono::Year.new
    year.year.must_equal Time.new.year
    year.corrected?.must_equal false
  end

  describe "when subtracting" do
    it "can subtract years" do
      (Chrono::Year.new(2015) - Chrono::Year.new(2014)).must_equal 1
    end

    it "can subtract integers" do
      (Chrono::Year.new(2015) - 1).year.must_equal 2014
    end
  end
end

describe Chrono::Month do
  it "must complain about non-integer months" do
    proc { Chrono::Month.new(2015, "6") }.must_raise TypeError
  end

  it "must know the current month" do
    month = Chrono::Month.new
    month.month.must_equal Time.new.month
    month.corrected?.must_equal false
  end

  describe "when given invalid months" do
    before do
      @month_neg = Chrono::Month.new(2015, -1)
      @month_13 = Chrono::Month.new(2015, 13)
      @month_0 = Chrono::Month.new(2015, 0)
    end

    it "must correct the month" do
      @month_neg.year.must_equal 2014
      @month_neg.month.must_equal 11
      @month_13.year.must_equal 2016
      @month_13.month.must_equal 1
      @month_0.year.must_equal 2014
      @month_0.month.must_equal 12
    end

    it "must know of the correction" do
      @month_neg.corrected?.must_equal true
      @month_13.corrected?.must_equal true
      @month_0.corrected?.must_equal true
    end
  end

  describe "when subtracting" do
    it "can subtract months" do
      (Chrono::Month.new(2015, 3) - Chrono::Month.new(2014, 12)).must_equal 3
    end

    it "can subtract integers" do
      (Chrono::Month.new(2015, 3) - 3).month.must_equal 12
    end
  end
end

describe Chrono::Date do
  it "must complain about non-integer days" do
    proc { Chrono::Date.new(2015, 1, "6") }.must_raise TypeError
  end

  it "must know the current date" do
    date = Chrono::Date.new
    date.day.must_equal Time.new.day
    date.corrected?.must_equal false
  end

  describe "when given invalid dates" do
    before do
      @day_neg = Chrono::Date.new(2015, 1, -1)
      @day_30 = Chrono::Date.new(2015, 2, 30)
      @day_0 = Chrono::Date.new(2015, 1, 0)
    end

    it "must correct the date" do
      @day_neg.year.must_equal 2014
      @day_neg.month.must_equal 12
      @day_neg.day.must_equal 30

      @day_30.year.must_equal 2015
      @day_30.month.must_equal 3
      @day_30.day.must_equal 2

      @day_0.year.must_equal 2014
      @day_0.month.must_equal 12
      @day_0.day.must_equal 31
    end

    it "must know of the correction" do
      @day_neg.corrected?.must_equal true
      @day_30.corrected?.must_equal true
      @day_0.corrected?.must_equal true
    end
  end
end

describe Chrono::Time do
  it "can handle missing initialize args" do
    checks = [
      [2014,  10,   1, 4,  38,  12],
      [ nil,  11,   2, 5,  39,  13],
      [ nil, nil,   3, 6,  40,  14],
      [ nil, nil, nil, 7,  41,  15],
      [ nil, nil, nil, 8,  42, nil],
      [ nil, nil, nil, 9, nil, nil],
    ]

    checks.each do |c|
      t = Chrono::Time.new(*c.compact)

      t.year.must_equal c[0] if c[0]
      t.month.must_equal c[1] if c[1]
      t.day.must_equal c[2] if c[2]
      t.hour.must_equal c[3] if c[3]
      t.minute.must_equal c[4] if c[4]
      t.second.must_equal c[5] if c[5]
    end
  end
end
