from cyinterval.cyinterval cimport DateIntervalSet, DateInterval, DateInterval_preprocess_intervals

cdef double float_inf = float('inf')
cdef int measure(DateInterval interval):
    cdef int result
    result = (interval.upper_bound - interval.lower_bound).days
    if interval.upper_closed:
        result += 1
    if not interval.lower_closed:
        result -= 1
    return result
cdef timedelta day = timedelta(days=1)

cdef class DateMap:
    def __init__(DateMap self, DateIntervalSet intervals):
        self.intervals = intervals
        self.period = 0
        self.bounded = True
        for interval in self.intervals.intervals:
            if interval.lower_bounded and interval.upper_bounded:
                self.period += measure(interval)
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
        cdef DateInterval intr
        for intr in self.intervals.intervals:
            if date < intr.lower_bound:
                break
            if intr.contains(date):
                result += (date - intr.lower_bound).days
                if not intr.lower_closed:
                    result -= 1
            elif intr.upper_bounded:
                result += measure(intr)
            else:
                raise ValueError('This line should never be reached.  There is a bug in cydatemap.')
        return timedelta(days=result)
    
    def date_of(DateMap self, int day):
        cdef int period = self.period
        if day >= period or day < -1*period:
            raise IndexError
        if day < 0:
            day = day % period
        remaining = day
        cdef DateInterval intr
        for intr in self.intervals:
            if intr.empty():
                continue
            result = intr.lower_bound if intr.lower_closed else intr.lower_bound + timedelta(days=1)
            duration = measure(intr)
            if remaining < duration:
                result += timedelta(days=remaining)
                break
            remaining -= duration
        return result
    
    def days_between(self, lower, upper, lower_closed, upper_closed):
        cdef DateIntervalSet intrv = DateIntervalSet((DateInterval(lower, upper, lower_closed, upper_closed, True, True),))
        cdef int total = 0
        cdef DateIntervalSet intersection = self.intervals.intersection(intrv)
        cdef DateInterval current
        for current in intersection:
            total += measure(current)
        return total
    
    def split(self, max_gap):
        '''
        Split into multiple datemaps on any gap larger than max_gap.
        '''
        if self.intervals.n_intervals < 2:
            return self
        cdef DateInterval previous, current
        previous = self.intervals[0]
        cdef date previous_upper = previous.upper_bound if previous.upper_closed else previous.upper_bound - day
        cdef date current_lower
        cdef list current_intervals = [previous]
        cdef list result = []
        for current in self.intervals[1:]:
            current_lower = current.lower_bound if current.lower_closed else current.lower_bound + day
            if (current_lower - previous_upper).days > max_gap:
                result.append(DateMap(DateIntervalSet(tuple(current_intervals))))
                current_intervals = []
            current_intervals.append(current)
            previous = current
            previous_upper = previous.upper_bound if previous.upper_closed else previous.upper_bound - day
        result.append(DateMap(DateIntervalSet(tuple(current_intervals))))
        return result
#         
#         current_upper = self.intervals[0].upper_bound if not self.intervals[0].upper_closed else self.intervals[0].upper_bound + day
#                 result = []
#         for interval in self.intervals[1:]:
#             current_lower = self.intervals[1].lower_bound if self.intervals[0].lower_closed else self.intervals[0].lower_bound + day
# 
#             if (interval.lower_bound - current_upper).days + (1 if not interval.lower_closed else 0) > max_gap:
#                 result.append((current_lower, current_upper))
#                 current_lower = interval.upper_bound if not interval.upper_closed else interval.upper_bound + day
#             current_upper = interval.upper_bound
#         result.append((current_lower, current_upper))
#         return [self.truncate(lower, upper) for lower, upper in result]
    
    


