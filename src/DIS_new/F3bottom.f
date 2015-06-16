************************************************************************
*
*     F3bottom.f:
*
*     This function returns the value of the bottom structure function
*     F3b.
*
************************************************************************
      function F3bottom(x)
*
      implicit none
*
      include "../commons/grid.h"
      include "../commons/StructureFunctions.h"
      include "../commons/TMC.h"
      include "../commons/TimeLike.h"
**
*     Input Variables
*
      double precision x
**
*     Internal Variables
*
      integer n
      integer alpha
      double precision w_int_gen
      double precision tau,xi
      double precision c1,c2
      double precision tol
      parameter(tol=1d-10)
**
*     Output Variables
*
      double precision F3bottom
*
*
      if(TMC)then
         tau = 1d0 + 4d0 * rhop * x**2d0
         xi  = 2d0 * x / ( 1d0 + dsqrt(tau) )
*
         c1 = x**2d0 / xi**2d0 / tau
         c2 = 4d0 * rhop * x**3d0 / tau**1.5d0
*
         if(xi.lt.xmin(1)-tol.or.xi.gt.xmax+tol)then
            write(6,*) "In F3bottom.f:"
            write(6,*) "Invalid value of x =",xi
            call exit(-10)
         endif
         if (xi.lt.xmin(1)) xi = xmin(1)
         if (xi.gt.xmax) xi = 1d0
*
*     Interpolation
*
         F3bottom = 0d0
         n = inter_degree(0)
         do alpha=0,nin(0)
            F3bottom = F3bottom + w_int_gen(n,alpha,xi) 
     1           * ( c1 * F3(5,0,alpha) + c2 * I3(5,0,alpha) )
         enddo
         if(dabs(F3bottom).le.1d-14) F3bottom = 0d0
      else
         if(x.lt.xmin(1)-tol.or.x.gt.xmax+tol)then
            write(6,*) "In F3bottom.f:"
            write(6,*) "Invalid value of x =",x
            call exit(-10)
         endif
         if (x.lt.xmin(1)) x = xmin(1)
         if (x.gt.xmax) x = 1d0
*
*     Interpolation
*
         F3bottom = 0d0
         n = inter_degree(0)
         do alpha=0,nin(0)
            F3bottom = F3bottom + w_int_gen(n,alpha,x) * F3(5,0,alpha)
         enddo
         if(dabs(F3bottom).le.1d-14) F3bottom = 0d0
      endif
*
      if(Timelike) F3bottom = F3bottom / x
*
      return
      end
