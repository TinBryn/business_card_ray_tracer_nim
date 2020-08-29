# An implementation of Andrew Kensler's "Business Card Ray Tracer" translated into Nim

![NIM](https://user-images.githubusercontent.com/1669043/91635008-65c11c00-ea27-11ea-9816-76772590a5a4.png)

I haven't minified it so it doesn't fit on a business card, I have however made some improvements

The original wrote directly to stdout and redirected stdout to a file in order to reduce code
and rather put that work on the shell. This version does all of that for you and uses stdout
as an information stream to track progress.

I've converted it to rather use a global random, to use a local random variable. I've also
made it write to a buffer of chars which are then all written to a file only at the end.

These 2 changes allow for the algorithm to be broken up so that each pixel or group of pixels
can be calculated completely independantly. This means it can easily be parallelelized which
has been done on a line basis.

Also I use a 2D array for the data and it now writes "NIM"

I'm working on getting refraction working, it's currently very broken.

## Performance

I've tested this on a Ryzen R7 2700X (8 core 16 thread) with 1024 samples per pixel at 1080p resolution
perf stat shows

      47,259,627.96 msec task-clock                #   15.790 CPUs utilized          
          6,674,340      context-switches          #    0.141 K/sec                  
              7,245      cpu-migrations            #    0.000 K/sec                  
              2,131      page-faults               #    0.000 K/sec                  
183,021,382,277,936      cycles                    #    3.873 GHz                      (83.33%)
  1,987,619,295,630      stalled-cycles-frontend   #    1.09% frontend cycles idle     (83.33%)
 26,923,029,033,766      stalled-cycles-backend    #   14.71% backend cycles idle      (83.33%)
252,678,712,192,192      instructions              #    1.38  insn per cycle         
                                                   #    0.11  stalled cycles per insn  (83.33%)
 32,757,139,314,024      branches                  #  693.132 M/sec                    (83.33%)
    167,256,353,422      branch-misses             #    0.51% of all branches          (83.33%)

     2992.948517901 seconds time elapsed

    47233.038144000 seconds user
       20.222541000 seconds sys

I'm not very familar with perf stat, the most significant performance issue I think is the
back end idles which I suspect are mostly the result of using `sqrt` when normalizing vectors.

## References
original: <http://eastfarthing.com/blog/2016-01-12-card/>
