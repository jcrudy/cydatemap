from cyinterval.cyinterval cimport DateIntervalSet

cdef class DateMap:
    def __init__(DateMap self, DateIntervalSet intervals):
        self.intervals = intervals