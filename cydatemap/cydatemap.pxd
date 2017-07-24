from cyinterval.cyinterval cimport DateIntervalSet

cdef class DateMap:
    cdef readonly DateIntervalSet intervals