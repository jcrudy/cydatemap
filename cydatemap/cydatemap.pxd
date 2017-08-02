from cyinterval.cyinterval cimport DateIntervalSet, DateInterval
from cpython cimport bool
from cpython.datetime cimport timedelta, date

cdef double float_inf
cdef int measure(DateInterval interval)
cdef class DateMap:
    cdef readonly DateIntervalSet intervals
    cdef readonly int period
    cdef readonly bool bounded