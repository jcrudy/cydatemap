from cyinterval.cyinterval cimport DateIntervalSet
from cpython cimport bool
from cpython.datetime cimport timedelta, date

cdef class DateMap:
    cdef readonly DateIntervalSet intervals
    cdef readonly int period
    cdef readonly bool bounded