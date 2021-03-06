## Copyright (C) 2018 Avinoam Kalma
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {Function File} {} integralImage (@var{img})
## @deftypefnx {Function File} {} integralImage (@var{img}, @var{orient})
##
## Calculates the integral image.
## The first input argument @var{img} is the input image for integral image calculation.
## If it is an RGB image (or higher dimension), each color plane is treated separately.
## The variable @var{orient} is string that determines which integral image will be
## calculated. Options are "upright" (default) or "rotated".
##
## The value of the integral image in the "upright" orientation, also called "summed-area table",
## at any poing (x, y) is  the sum of all the pixels above and to the left of (x, y), inclusive, see [1]
##
## When using the "rotated" option, Rotated Summed Area Table (RSAT) is calculated.
## It is defined as the sum of the pixels of a 45 degrees rotated rectangle with the
## bottom most corner at (x,y):
## 
## RSAT(x,y) = RSAT(x-1,y-1) + RSAT(x+1,y-1) - RSAT(x,y-2) + I(x,y) + I(x,y-1)
## (see [2])
##
## @strong{References}
##
## [1] Viola, Paul; Jones, Michael (2002). "Robust Real-time Object Detection".
## International Journal of Computer Vision.
## @url{http://www.hpl.hp.com/techreports/Compaq-DEC/CRL-2001-1.pdf}
##
## [2] Lienhart, Kuranov and Pisarevsky (2002).
## "Empirical Analysis of Detection Cascades of Boosted Classifiers for Rapid Object Detection"
## @url{http://www.multimedia-computing.de/mediawiki/images/5/52/MRL-TR-May02-revised-Dec02.pdf}
##
## @end deftypefn

function J = integralImage (I, orientation = "upright")

  pkg load image

  if (nargin < 1 || nargin > 2)
    print_usage ();
  endif

  if (! strcmp (class(I), "double"))
    I = double(I);
  endif

  orientation = lower (orientation);
  if (strcmp (orientation, "upright"))
    J = cumsum (cumsum (I, 2));
    J = padarray (J, [1 1], "pre");
  elseif (strcmp (orientation, "rotated"))
    if (ndims (I) == 2)
      J = integralImage_rotate_2D (I);
    else
      IR = reshape (I, size (I,1), size (I,2), []);
      J = zeros (size (IR,1)+1, size (IR,2)+2, size (IR,3));
    for i = 1:size (IR,3)
      J(:,:,i) = integralImage_rotate_2D (IR(:,:,i));
    endfor
      s = size (I);
      J = reshape (J, [size(J,1) size(J,2) s(3:end)]);
    endif
  else
    error ("orientation should be \"upright\" (default) or \"rotated\"");
  endif
  J = J(2:size(J,1), 2:size(J,2));
endfunction

function J = integralImage_rotate_2D (I)
  ## FIXME: This part should be vectorized
  s = size(I);
  s1 = s;
  s1(1) = s1(1)+1;
  s1(2) = s1(2)+2;
  J = zeros (s1);
  for x = 2:s(2)+1
    J(2, x) = I(1, x-1);
  endfor
  for y=3:s1(1)
    J(y, 1) = J(y-1, 2);
    for x=2:s1(2)-1
      J(y, x) = J(y-1, x-1) + J(y-1, x+1) - J(y-2, x) + I(y-1, x-1) + I(y-2, x-1);
    endfor
    J(y, end) = J(y-1, end-1);
  endfor
endfunction

%!test
%! assert (integralImage (10), [0 0; 0 10]);
%! assert (integralImage (10, "rotated"), [0 0 0; 0 10 0]);

%!test
%! J = integralImage (10);
%! assert (class(J), "double");
%! J = integralImage (uint8(10));
%! assert (class(J), "double");

%!test
%! I = [1, 2; 3, 4];
%! J = integralImage (I);
%! J1 = [0 0 0; 0 1 3; 0 4 10];
%! assert (J, J1)
%! J = integralImage (I, "rotated");
%! J1 = [0 0 0 0; 0 1 2 0; 1 6 7 2];
%! assert (J, J1)

%!test
%! I1 = [1, 2; 3, 4];
%! I2 = [5, 6; 7, 8];
%! I3 = [9, 10; 11, 12];
%! I = cat (3, I1, I2, I3);
%! J = integralImage (I); 
%! J1 = [0 0 0; 0 1 3; 0 4 10];
%! J2 = [0 0 0; 0 5 11; 0 12 26];
%! J3 = [0 0 0; 0 9 19; 0 20 42];
%! J0 = cat (3, J1, J2, J3);
%! assert (J, J0)

%!test
%! I1 = [1, 2; 3, 4];
%! I2 = [5, 6; 7, 8];
%! I3 = [9, 10; 11, 12];
%! I = cat (3, I1, I2, I3);
%! J = integralImage (I, "rotated"); 
%! J1 = [0 0 0 0; 0 1 2 0; 1 6 7 2];
%! J2 = [0 0 0 0; 0 5 6 0; 5 18 19 6];
%! J3 = [0 0 0 0; 0 9 10 0; 9 30 31 10];
%! J0 = cat (3, J1, J2, J3);
%! assert (J, J0)

%!error
%! integralImage (); 

%!error
%! integralImage (1, "xxx", 2); 

%!error <integralImage: first argument should be an image>
%! integralImage ("abcd"); 

%!error <orientation should be "upright">
%! integralImage ([1 2; 3 4], "xxx"); 
