from cyinterval.cyinterval cimport DateIntervalSet, DateInterval, DateInterval_preprocess_intervals

cdef double float_inf = float('inf')
cdef class DateMap:
    def __init__(DateMap self, DateIntervalSet intervals):
        self.intervals = intervals
        self.period = 0
        self.bounded = True
        for interval in self.intervals.intervals:
            if interval.lower_bounded and interval.upper_bounded:
                self.period += (interval.upper_bound - interval.lower_bound).days
                if interval.upper_closed:
                    print 'a'
                    self.period += 1
                if not interval.lower_closed:
                    print 'b'
                    self.period -= 1
            else:
                self.bounded = False
                break
        
        
    @classmethod
    def from_tuples(cls, list tuples):
        intervals = []
        for policy in tuples:
            intr = DateInterval(policy[0],policy[1],lower_closed=True,upper_closed=False,lower_bounded=True,upper_bounded=True)
            intervals.append(intr)
        return cls(DateIntervalSet(DateInterval_preprocess_intervals(tuple(intervals))))
    
    def __or__(DateMap self, other):
        if other.__class__ is not DateMap:
            return NotImplemented
        return DateMap(self.intervals.union(other.intervals))
    
    def __ror__(DateMap self, other):
        if other.__class__ is not DateMap:
            return NotImplemented
        return other.__or__(self)
    
    def __and__(DateMap self, other):
        if other.__class__ is not DateMap:
            return NotImplemented
        return DateMap(self.intervals.intersection(other.intervals))
    
    def __rand__(DateMap self, other):
        if other.__class__ is not DateMap:
            return NotImplemented
        return other.__and__(self)
    
    def __sub__(DateMap self, other):
        if other.__class__ is not DateMap:
            return NotImplemented
        return self.__class__(self.intervals.minus(other.intervals))
    
    def __rsub__(DateMap self, other):
        if other.__class__ is not DateMap:
            return NotImplemented
        return other.__sub__(self)
    
    def __invert__(DateMap self):
        return DateMap(self.intervals.complement())
    
    def __richcmp__(DateMap self, other, int op):
        if other.__class__ is not DateMap:
            return NotImplemented
        if op == 2:
            return self.intervals.equal(other.intervals)
        return NotImplemented
    
    def __req__(DateMap self, other):
        if other.__class__ is not DateMap:
            return NotImplemented
        return other.__eq__(self)
    
    def __contains__(DateMap self, date date):
        return self.intervals.contains(date)
    
    def truncate(DateMap self, lower=None, upper=None):
        '''Return a copy truncated above and/or below.'''
        cdef DateInterval interval
        if lower is not None:
            if upper is not None:
                interval = DateInterval(lower, upper, lower_closed=True, upper_closed=False, lower_bounded=True, upper_bounded=True)
            else:
                interval = DateInterval(lower, lower, lower_closed=True, upper_closed=False, lower_bounded=True, upper_bounded=False)
        else:
            if upper is not None:
                interval = DateInterval(upper, upper, lower_closed=True, upper_closed=False, lower_bounded=False, upper_bounded=True)
            else:
                return self
        return DateMap(self.intervals.intersection(DateIntervalSet((interval,))))
    
    def __len__(DateMap self):
        return len(self.intervals.intervals)
    
    def delta_of(DateMap self, date date):
        if date not in self:
            raise ValueError('%s not in %s' % (str(date), str(self.intervals)))
        if not self.intervals.lower_bounded():
            raise ValueError('%s not bounded below' % str(self.intervals))
        cdef int result = 0
        for intr in self.intervals.intervals:
            if date < intr.lower_bound:
                break
            if intr.upper_bounded:
                result += (min(intr.upper_bound, date) - intr.lower_bound).days
            else:
                result += (date - intr.lower_bound).days
        return timedelta(days=result)
    
    def date_of(DateMap self, int day):
        if isinstance(day, timedelta):
            day = day.days
        cdef int period = self.period
        if day >= period or day < -1*period:
            raise IndexError
        if day < 0:
            day = day % period
        remaining = day
        for intr in self.intervals:
            result = intr.lower_bound
            duration = (intr.upper_bound - intr.lower_bound).days
            if remaining < duration:
                result += timedelta(days=remaining)
                break
            remaining -= duration
        return result
    
    


