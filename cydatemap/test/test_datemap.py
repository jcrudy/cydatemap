'''
Created on Nov 14, 2012

@author: jason
'''
from datetime import date as d, timedelta as td
from cydatemap.cydatemap import DateMap
from nose.tools import assert_equal, assert_not_equal, assert_raises  # @UnresolvedImport

def assert_contains(a, b):
    assert a in b

def assert_not_contains(a, b):
    assert a not in b
    
def assert_less(a, b):
    assert a < b

def assert_less_equal(a, b):
    assert a <= b

def assert_greater(a, b):
    assert a > b

def assert_greater_equal(a, b):
    assert a >= b

# class TestEternity(object):
#     def test_eternity(self):
#         dt = d(2001,1,1)
#         assert_less(dt,eternity)
#         assert_less_equal(dt,eternity)
#         assert_greater(eternity,dt)
#         assert_greater_equal(eternity,dt)
#         assert_less(-eternity,dt)
#         assert_less_equal(-eternity,dt)
#         assert_greater(dt,-eternity)
#         assert_greater_equal(dt,-eternity)
#         assert_less(-eternity,eternity)
#         assert_less_equal(-eternity,eternity)
#         assert_greater(eternity,-eternity)
#         assert_greater_equal(eternity,-eternity)
#         assert_equal(eternity,eternity)
#         assert_equal(-eternity,-eternity)
#         assert_not_equal(dt,eternity)
#         assert_not_equal(eternity,dt)
#         assert_not_equal(dt,-eternity)
#         assert_not_equal(-eternity,dt)
#         assert_not_equal(-eternity,eternity)
#         assert_not_equal(eternity,-eternity)
#         assert_equal([-eternity,dt,eternity],sorted([dt,eternity,-eternity]))
#         assert_equal(eternity,--eternity)
#         assert_equal(-eternity,---eternity)
        
class TestDateMap(object):


    def setUp(self):
        self.y2001 = (d(2001,1,1),d(2002,1,1))
        self.y2002 = (d(2002,1,1),d(2003,1,1))
        self.y2003 = (d(2003,1,1),d(2004,1,1))
        self.y2004 = (d(2004,1,1),d(2005,1,1))
        self.y2005 = (d(2005,1,1),d(2006,1,1))
        self.y2006 = (d(2006,1,1),d(2007,1,1))

    def tearDown(self):
        pass
    
    def test_split(self):
        dm = DateMap.from_tuples([self.y2001, self.y2003, self.y2006])
        assert dm.split(364) == [DateMap.from_tuples([tup]) for tup in [self.y2001, self.y2003, self.y2006]]
        assert dm.split(365) == [DateMap.from_tuples(tups) for tups in [[self.y2001, self.y2003], [self.y2006]]]

    def test_in(self):
        dm = DateMap.from_tuples([self.y2001,self.y2003])
        assert_contains(d(2001,5,5),dm)
        assert_contains(d(2001,1,1),dm)
        assert_not_contains(d(2002,1,1),dm)
        assert_not_contains(d(2000,12,31),dm)
        assert_contains(d(2003,1,1),dm)
        assert_not_contains(d(2004,1,1),dm)
        assert_not_contains(d(2002,12,31),dm)
        
    def test_period(self):
        dm = DateMap.from_tuples([self.y2001,self.y2003])
        assert_equal(dm.period,2*365)
        dm2 = DateMap.from_tuples([self.y2001,self.y2003,self.y2004])
        assert_equal(dm2.period,3*365+1)#2004 was a leap year
        
    def test_delta_of(self):
        dm = DateMap.from_tuples([self.y2001,self.y2003,self.y2004])
        assert_raises(ValueError,dm.delta_of,d(2000,12,31))
        assert_equal(dm.delta_of(d(2001,12,31)).days,364)
        assert_equal(dm.delta_of(d(2003,12,31)).days,2*364+1)
        assert_equal(dm.delta_of(d(2004,12,31)).days,3*364+3)#2004 was a leap year
        assert_raises(ValueError,dm.delta_of,d(2005,1,2))
    
    def test_date_of(self):
        dm = DateMap.from_tuples([self.y2001,self.y2003,self.y2004])
        assert_equal(d(2004,12,31),dm.date_of(-1))
        assert_equal(d(2001,12,31),dm.date_of(364))
        assert_equal(d(2003,12,31),dm.date_of(2*364+1))
        assert_equal(d(2004,12,31),dm.date_of(3*364+3))#2004 was a leap year
        assert_raises(IndexError,dm.date_of,3*364+3+2)
        dm2 = DateMap.from_tuples([(d(2001,1,3),d(2001,1,7)),(d(2001,1,15),d(2001,1,22))])
        for day in range(-10,40):
            date = d(2001,1,3) + td(days=day)
            if date in dm2:
                assert_equal(date,dm2.date_of(dm2.delta_of(date).days))
    
    def test_partition(self):
        dm = DateMap.from_tuples([self.y2001,self.y2003])
        dm2001 = DateMap.from_tuples([self.y2001])
        dm2003 = DateMap.from_tuples([self.y2003])
        jan2001 = DateMap.from_tuples([(d(2001,1,1), d(2001,2,1))])
        feb2001 = DateMap.from_tuples([(d(2001,2,1),d(2001,3,1))])
        the_rest = dm - jan2001 - feb2001
        partitions1 = dm.partition([365,365])
        assert_equal(partitions1[0], dm2001)
        assert_equal(partitions1[1], dm2003)
        partitions2 = dm.partition([0,31,28,0,dm.period - 31 - 28,0])
        assert_equal(partitions2[0], DateMap.from_tuples([]))
        assert_equal(partitions2[1], jan2001)
        assert_equal(partitions2[2], feb2001)
        assert_equal(partitions2[3], DateMap.from_tuples([(d(2001,3,1),d(2001,3,1))]))
        assert_equal(partitions2[4], the_rest)
        assert_equal(partitions2[5], DateMap.from_tuples([]))
        assert_equal(sum([part.period for part in partitions2]),dm.period)
    
    def test_slice(self):
        dm = DateMap.from_tuples([self.y2003, self.y2005])
        days = dm.period
        assert dm.slice(upper=days) == dm
        
#     def test_invert(self):
#         dm1 = DateMap.from_tuples([self.y2001,self.y2003,self.y2004])
#         dm2 = DateMap.from_tuples([self.y2003, self.y2005])
#         dm3 = DateMap.from_tuples([self.y2001, self.y2004])
#         dm4 = DateMap.from_tuples([self.y2005])
#         assert_equal(dm3, dm1 & ~dm2)
#         assert_equal(dm4, dm2 & ~dm1)
    
    def test_sub(self):
        dm1 = DateMap.from_tuples([self.y2001,self.y2003,self.y2004])
        dm2 = DateMap.from_tuples([self.y2003, self.y2005])
        dm3 = DateMap.from_tuples([self.y2001, self.y2004])
        dm4 = DateMap.from_tuples([self.y2005])
        assert_equal(dm3, dm1 - dm2)
        assert_equal(dm4, dm2 - dm1)
        
    def test_truncate(self):
        dm = DateMap.from_tuples([self.y2001,self.y2003])
        dm2 = dm.truncate(lower=d(2001,5,5))
        assert_contains(d(2001,5,5),dm2)
        assert_not_contains(d(2001,1,1),dm2)
        assert_not_contains(d(2002,1,1),dm2)
        assert_not_contains(d(2000,12,31),dm2)
        assert_contains(d(2003,1,1),dm2)
        assert_not_contains(d(2004,1,1),dm2)
        assert_not_contains(d(2002,12,31),dm2)
        assert_contains(d(2003,12,31),dm2)
        assert_equal(dm,dm.truncate())
        assert_equal(dm,dm.truncate(d(1300,2,14),d(2064,10,31)))
        assert_not_equal(2,dm)
        class Equalizer(object):
            def __eq__(self, other):
                return True
        assert_equal(Equalizer(),dm)
        assert_equal(dm,Equalizer())
        class Discriminator(object):
            def __eq__(self, other):
                return False
        assert_not_equal(Discriminator(),dm)
        assert_not_equal(dm,Discriminator())
        class FenceSitter(object):
            def __eq__(self, other):
                return NotImplemented
        assert_not_equal(FenceSitter(),dm)
        assert_not_equal(dm,FenceSitter())
        
        
if __name__ == '__main__':
    import sys
    import nose
    #This code will run the tests in this file.'

    module_name = sys.modules[__name__].__file__

    result = nose.run(argv=[sys.argv[0],
                            module_name,
                            '-s','-v'])