Copyright (c) 2019 Adam Solesby  https://github.com/solesby/



This is a simple Django model for storing US Zip Code data.

You can purchase and download the source zip code data from:

https://www.zip-info.com/products/z5ll/z5ll.htm

You will need the file `z5ll.txt` from the archive. You can load the file (optionally compressed):

    USZipcode.import_zipinfo('z5ll.txt.gz')

The Zipcode class helps perform queries on USZipcode. Chain together as you would a QuerySet.


    qs = Zipcode( 37215 ).within_distance( 50 ).filter(...).exclude(...)

This will return a QuerySet with USZipcode within 50 miles of 37215. Each will also have the approximate 
distance in miles from the center of 37215.

Note: this uses a pre-calculated square for simple DB index

You can return a flat list of zip codes:

    zips = Zipcode( 37215 ).within_distance( 50 ).flat()
    
    >>> ['37215','37201','37202',...]

