# An implementation of Andrew Kensler's "Business Card Ray Tracer" translated into Nim

![NIM](https://user-images.githubusercontent.com/1669043/91628493-d1d55d00-e9f2-11ea-97bd-b0cc4e28e3ce.png)

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

## References
original: <http://eastfarthing.com/blog/2016-01-12-card/>
