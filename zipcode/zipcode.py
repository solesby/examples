## Simple django zipcode models
##
## Copyright (c) 2019 Adam Solesby  https://github.com/solesby/
##
## The MIT License (MIT)
##
## Permission is hereby granted, free of charge, to any person obtaining a copy of
## this software and associated documentation files (the "Software"), to deal in
## the Software without restriction, including without limitation the rights to
## use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
## the Software, and to permit persons to whom the Software is furnished to do so,
## subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
## FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
## COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
## IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

from django.db                   import models
from django.core.management.base import BaseCommand
from decimal import Decimal


class USZipcode(models.Model):
    zipcode     = models.CharField(max_length=5 , blank=False, null=False, db_index=True, primary_key=True)
    city        = models.CharField(max_length=28, blank=False, null=False, db_index=True)
    state       = models.CharField(max_length=2 , blank=False, null=False, db_index=True)
    latitude    = models.DecimalField(max_digits=10, decimal_places=8, blank=True, null=True, default=None, db_index=True)
    longitude   = models.DecimalField(max_digits=11, decimal_places=8, blank=True, null=True, default=None, db_index=True)
    county      = models.CharField(max_length=50, blank=True , null=True, default=None)
    county_fips = models.CharField(max_length=5 , blank=True , null=True, default=None)
    area_code   = models.CharField(max_length=3 , blank=True , null=True, default=None, db_index=True)
    timezone    = models.CharField(max_length=20, blank=False, null=False)
    kind        = models.CharField(max_length=1,  blank=True , null=False, db_index=True, choices=(('','Regular'),('M','Military'),('P','PO Box'),('U','Unique')), default='')

    class Meta:
        db_table = 'us_zipcode'
        ordering = [ 'zipcode' ]

    def __str__(self):
        return ' '.join((str(self.zipcode), self.city, self.state)).strip()


    def distance(self):
        # Approximate distance in miles = sqrt(x * x + y * y) where
        # x = 69.1 * (zip2.lat - zip1.lat)
        # y = 53   * (zip2.lon - zip1.lon)
        # NOTE: this method will get overridden if distance is added in Queryset below
        if getattr(self, 'center_lat', 0) and getattr(self, 'center_lon', 0):
            x = Decimal( 69.1 ) * (self.latitude  - Decimal( self.center_lat ))
            y = Decimal( 53.0 ) * (self.longitude - Decimal( self.center_lon ))
            return (x * x + y * y).sqrt()
        return 0


    @classmethod
    def import_zipinfo(cls, filename='z5ll.txt'):
        '''
            https://www.zip-info.com/products/z5ll/z5ll.htm

            City   City Name      Variable     28 maximum
            ST     State Code     Fixed        2 alpha characters
            ZIP    ZIP code       Fixed        5 numeric characters
            A/C    Area code      Fixed        3 numeric characters
            FIPS   County FIPS    Fixed        5 numeric characters
            County County Name    Variable     25 alphabetic characters
            T/Z    Time zone      Variable     5 maximum (see below)
            DST?   DST?           Fixed        1 character: "Y" or "N"
            Lat    Latitude       Variable     7 or 8 chars: nn.nnnn (NAD-83 coordinates)
            Long   Longitude      Variable     9 or 10 chars: -nnn.nnnn (NAD-83 coordinates)
            Type   ZIP code type  Fixed        1 char (P, U, M, or blank)
        '''

        tz_map = {
            'EST+1': 'America/Puerto_Rico', ## 'America/Puerto_Rico'  GMT-4   Puerto Rico, Virgin Islands, APO/FPO (Central America)
            'EST':   'US/Eastern'         , ## 'America/New_York'     GMT-5   Eastern standard time
            'CST':   'US/Central'         , ## 'America/Chicago'      GMT-6   Central standard time
            'MST':   'US/Mountain'        , ## 'America/Denver'       GMT-7   Mountain standard time
            'PST':   'US/Pacific'         , ## 'America/Los_Angeles'  GMT-8   Pacific standard time
            'PST-1': 'US/Alaska'          , ## 'America/Anchorage'    GMT-9   Alaska (except Aleutian Islands)
            'PST-2': 'US/Hawaii'          , ## 'Pacific/Honolulu'     GMT-10  Hawaii, Aleutian Islands
            'PST-3': 'Pacific/Pago_Pago'  , ## 'Pacific/Pago_Pago'    GMT-11  Pago Pago
            'PST-4': 'Pacific/Majuro'     , ## 'Pacific/Majuro'       GMT+12  Marshall Islands, W ake Island Micronesia
            'PST-6': 'Pacific/Guam'       , ## 'Pacific/Guam'         GMT+10  Guam
            'GMT+1': 'GMT+1'              , ##                        GMT+1   APO/FPO (Central Europe)
            'PST-5': 'GMT+11'             , ##                        GMT+11  Micronesia
            'PST-7': 'GMT+9'              , ##                        GMT+9   APO/FPO (Pacific)
        }

        import csv, gzip

        if filename.endswith('.gz'):
            csvfile = gzip.open(filename, mode='rt', newline='\n')
        else:
            csvfile = open(filename, newline='\n')

        reader = csv.DictReader(csvfile, delimiter=',', quotechar='"')

        for row in reader:
            zipcode = row.get('ZIP', '').strip()
            if len(zipcode) < 5: continue

            z             = USZipcode(zipcode)
            z.city        = row['City']
            z.state       = row['ST']
            z.county      = row['County']
            z.county_fips = row['FIPS']
            z.kind        = row['Type']
            z.area_code   = row['A/C']
            z.latitude    = Decimal( row.get('Lat' ,'0') ) or None
            z.longitude   = Decimal( row.get('Long','0') ) or None
            z.timezone    = tz_map.get( row.get('T/Z',''), 'UTC' )
            z.save()



class Zipcode(object):

    def __init__(self, zipcode):
        self.us_zipcode = USZipcode.objects.get(zipcode=zipcode)
        self.zipcode    = zipcode
        self.latitude   = self.us_zipcode.latitude
        self.longitude  = self.us_zipcode.longitude


    def within_distance(self, distance, use_km=False):
        '''
        Return queryset of zipcodes within a box `distance` miles.
        Note: this uses a pre-calculated square for simple DB index
           Zipcode( 90210 ).within_distance( 50 ).filter(...)
        '''
        distance = distance * 0.621371 if use_km else distance
        lat_distance = distance / 69.1  # miles per deg of latitude
        lon_distance = distance / 53.0  # miles per deg of longitude
        lat_range = ( self.latitude  - Decimal(lat_distance), self.latitude  + Decimal(lat_distance))
        lon_range = ( self.longitude - Decimal(lon_distance), self.longitude + Decimal(lon_distance))

        v      = { 'lat':self.latitude, 'lon':self.longitude }
        v['x'] = '(69.1 * (latitude  - {lat}))'.format(**v)
        v['y'] = '(53   * (longitude - {lon}))'.format(**v)
        distance_sql = 'sqrt({x}*{x} + {y}*{y})'.format(**v)

        return USZipcode.objects.filter(latitude__range=lat_range, longitude__range=lon_range).extra(
            select={'center_lat': self.latitude, 'center_lon': self.longitude, 'distance': distance_sql, }
        ).order_by('distance')

