This library is a small experiment in handling time in a more object-oriented
way.

In contrast to Ruby's built-in `Time`, `Date`, and `DateTime` classes which are
redundant and inconsistent, this library defines four classes in the `Chrono`
module

    Year
    Month
    Date
    Time

where `Year` is the base class and each subsequent class is a subclass of the
previous one. As you might expect, instances of `Year` represent particular
years: 2015, 1988, etc. The trick is that `Month` objects don't just represent
months like "June" or "September", they represent _particular_ months like "June
2015" or "September 1988". This allows `Month` to be a proper subclass of `Year`
in the strict object-oriented sense; `Month` merely adds additional information
about the month to the `Year` class. `Date` and `Time` work similarly by adding
the day of the month and time of the day.

I think that this design allows for elegant handling of time in a program since
the structure of the classes can be relied on to produce intuitive code.
