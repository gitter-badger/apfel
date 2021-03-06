************************************************************************
*
*     IncludeScaleVariation.f:
*
*     This routine includes in the precomputed coefficient functions
*     all the scale variation terms that were not included in 
*     RSLintegralsDIS.f (or RSLintegralsSIA.f)
*
************************************************************************
      subroutine IncludeScaleVariation
*
      implicit none
*
      include "../commons/ipt.h"
      include "../commons/grid.h"
      include "../commons/integrals.h"
      include "../commons/coeffhqmellin.h"
      include "../commons/integralsDIS.h"
      include "../commons/MassScheme.h"
      include "../commons/Nf_FF.h"
      include "../commons/krenQ.h"
      include "../commons/kfacQ.h"
      include "../commons/DynScVar.h"
      include "../commons/MassInterpolIndices.h"
**
*     Internal Variables
*
      integer beta,alpha
      integer inf,jxi
      integer k
      integer gamma
      integer mapP(2,2),mapC(2)
      integer gbound
      integer ipt_FF
      double precision C12P0(4)
      double precision C1LP0(4)
      double precision C13P0(4)
      double precision P0P0(4)
      double precision tR,tF,tF2h
      double precision beta0apf,b0,omlam
*
      if(ipt.eq.0) return
      if(krenQ.eq.1d0.and.kfacQ.eq.1d0) return
*
      tR   = dlog(krenQ)
      tF   = dlog(kfacQ)
      tF2h = tF * tF / 2d0
*
*     If the dynamical scale variation has been enabled
*     set the renormalization scale equal to the factorization scale.
*
      if(DynScVar) tR = tF
*
*     Maps used for the muliplications
*
      mapP(1,1) = 4
      mapP(1,2) = 5
      mapP(2,1) = 6
      mapP(2,2) = 7
*
      mapC(1) = 3
      mapC(2) = 1
*     
*     If an external grid is found compute the whole operator
*     
      gbound = 0
      if(IsExt(igrid)) gbound = nin(igrid) - 1
*
*     ZM-VFNS (Compute it always)
*
      do inf=3,6
*
         b0 = beta0apf(inf)
*
*     NNLO
*
         if(ipt.ge.2)then
            do beta=0,gbound
               do alpha=beta,nin(igrid)-1
*
*     Precompute needed convolutions
*
                  do k=1,4
                     P0P0(k)  = 0d0
                     C12P0(k) = 0d0
                     C1LP0(k) = 0d0
                     C13P0(k) = 0d0
                  enddo
*
*     External grid
*
                  if(IsExt(igrid))then
                     do gamma=beta,alpha
*     Gluon
                        P0P0(1) = P0P0(1)
     1                       + SP(igrid,inf,mapP(1,1),0,beta,gamma)
     2                       * SP(igrid,inf,mapP(1,2),0,gamma,alpha)
     3                       + SP(igrid,inf,mapP(1,2),0,beta,gamma)
     4                       * SP(igrid,inf,mapP(2,2),0,gamma,alpha)
                        C12P0(1) = C12P0(1)
     1                       + SC2zm(igrid,inf,mapC(1),1,beta,gamma)
     2                       * SP(igrid,inf,mapP(1,2),0,gamma,alpha)
     3                       / inf
     4                       + SC2zm(igrid,inf,mapC(2),1,beta,gamma)
     5                       * SP(igrid,inf,mapP(2,2),0,gamma,alpha)
                        C1LP0(1) = C1LP0(1)
     1                       + SCLzm(igrid,inf,mapC(1),1,beta,gamma)
     2                       * SP(igrid,inf,mapP(1,2),0,gamma,alpha)
     3                       / inf
     4                       + SCLzm(igrid,inf,mapC(2),1,beta,gamma)
     5                       * SP(igrid,inf,mapP(2,2),0,gamma,alpha)
                        C13P0(1) = C13P0(1)
     1                       + SC3zm(igrid,inf,mapC(1),1,beta,gamma)
     2                       * SP(igrid,inf,mapP(1,2),0,gamma,alpha)
     3                       / inf
     4                       + SC3zm(igrid,inf,mapC(2),1,beta,gamma)
     5                       * SP(igrid,inf,mapP(2,2),0,gamma,alpha)
*     Pure-singlet
                        P0P0(2) = P0P0(2)
     1                       + SP(igrid,inf,mapP(1,2),0,beta,gamma)
     2                       * SP(igrid,inf,mapP(2,1),0,gamma,alpha)
                        C12P0(2) = C12P0(2)
     1                       + SC2zm(igrid,inf,mapC(2),1,beta,gamma)
     2                       * SP(igrid,inf,mapP(2,1),0,gamma,alpha)
                        C1LP0(2) = C1LP0(2)
     1                       + SCLzm(igrid,inf,mapC(2),1,beta,gamma)
     2                       * SP(igrid,inf,mapP(2,1),0,gamma,alpha)
                        C13P0(2) = C13P0(2)
     1                       + SC3zm(igrid,inf,mapC(2),1,beta,gamma)
     2                       * SP(igrid,inf,mapP(2,1),0,gamma,alpha)
*     Plus
                        P0P0(3) = P0P0(3)
     1                       + SP(igrid,inf,1,0,beta,gamma)
     2                       * SP(igrid,inf,1,0,gamma,alpha)
                        C12P0(3) = C12P0(3)
     1                       + SC2zm(igrid,inf,3,1,beta,gamma)
     2                       * SP(igrid,inf,1,0,gamma,alpha)
                        C1LP0(3) = C1LP0(3)
     1                       + SCLzm(igrid,inf,3,1,beta,gamma)
     2                       * SP(igrid,inf,1,0,gamma,alpha)
                        C13P0(3) = C13P0(3)
     1                       + SC3zm(igrid,inf,3,1,beta,gamma)
     2                       * SP(igrid,inf,1,0,gamma,alpha)
                     enddo
*
*     Internal grid
*
                  else
                     do gamma=beta,alpha
*     Gluon
                        P0P0(1) = P0P0(1)
     1                       + SP(igrid,inf,mapP(1,1),0,0,gamma-beta)
     2                       * SP(igrid,inf,mapP(1,2),0,0,alpha-gamma)
     3                       + SP(igrid,inf,mapP(1,2),0,0,gamma-beta)
     4                       * SP(igrid,inf,mapP(2,2),0,0,alpha-gamma)
                        C12P0(1) = C12P0(1)
     1                       + SC2zm(igrid,inf,mapC(1),1,0,gamma-beta)
     2                       * SP(igrid,inf,mapP(1,2),0,0,alpha-gamma)
     3                       / inf
     4                       + SC2zm(igrid,inf,mapC(2),1,0,gamma-beta)
     5                       * SP(igrid,inf,mapP(2,2),0,0,alpha-gamma)
                        C1LP0(1) = C1LP0(1)
     1                       + SCLzm(igrid,inf,mapC(1),1,0,gamma-beta)
     2                       * SP(igrid,inf,mapP(1,2),0,0,alpha-gamma)
     3                       / inf
     4                       + SCLzm(igrid,inf,mapC(2),1,0,gamma-beta)
     5                       * SP(igrid,inf,mapP(2,2),0,0,alpha-gamma)
                        C13P0(1) = C13P0(1)
     1                       + SC3zm(igrid,inf,mapC(1),1,0,gamma-beta)
     2                       * SP(igrid,inf,mapP(1,2),0,0,alpha-gamma)
     3                       / inf
     4                       + SC3zm(igrid,inf,mapC(2),1,0,gamma-beta)
     5                       * SP(igrid,inf,mapP(2,2),0,0,alpha-gamma)
*     Pure-singlet
                        P0P0(2) = P0P0(2)
     1                       + SP(igrid,inf,mapP(1,2),0,0,gamma-beta)
     2                       * SP(igrid,inf,mapP(2,1),0,0,alpha-gamma)
                        C12P0(2) = C12P0(2)
     1                       + SC2zm(igrid,inf,mapC(2),1,0,gamma-beta)
     2                       * SP(igrid,inf,mapP(2,1),0,0,alpha-gamma)
                        C1LP0(2) = C1LP0(2)
     1                       + SCLzm(igrid,inf,mapC(2),1,0,gamma-beta)
     2                       * SP(igrid,inf,mapP(2,1),0,0,alpha-gamma)
                        C13P0(2) = C13P0(2)
     1                       + SC3zm(igrid,inf,mapC(2),1,0,gamma-beta)
     2                       * SP(igrid,inf,mapP(2,1),0,0,alpha-gamma)
*     Plus
                        P0P0(3) = P0P0(3)
     1                       + SP(igrid,inf,1,0,0,gamma-beta)
     2                       * SP(igrid,inf,1,0,0,alpha-gamma)
                        C12P0(3) = C12P0(3)
     1                       + SC2zm(igrid,inf,3,1,0,gamma-beta)
     2                       * SP(igrid,inf,1,0,0,alpha-gamma)
                        C1LP0(3) = C1LP0(3)
     1                       + SCLzm(igrid,inf,3,1,0,gamma-beta)
     2                       * SP(igrid,inf,1,0,0,alpha-gamma)
                        C13P0(3) = C13P0(3)
     1                       + SC3zm(igrid,inf,3,1,0,gamma-beta)
     2                       * SP(igrid,inf,1,0,0,alpha-gamma)
                     enddo
                  endif
*     Minus ( = Plus)
                  P0P0(4)  = P0P0(3)
                  C12P0(4) = C12P0(3)
                  C1LP0(4) = C1LP0(3)
                  C13P0(4) = C13P0(3)
*
*     Now adjust the NNLO coefficient functions
*
*     Gluon
                  SC2zm(igrid,inf,1,2,beta,alpha) = 
     1                 SC2zm(igrid,inf,1,2,beta,alpha)
     2                 + tR * b0 * SC2zm(igrid,inf,1,1,beta,alpha)
     3                 - tF * C12P0(1)
     4                 + tF2h * ( P0P0(1)
     5                 - b0 * SP(igrid,inf,mapP(1,2),0,beta,alpha) )
     6                 / inf
     7                 - tF * SP(igrid,inf,mapP(1,2),1,beta,alpha) / inf
                  SCLzm(igrid,inf,1,2,beta,alpha) = 
     1                 SCLzm(igrid,inf,1,2,beta,alpha)
     2                 + tR * b0 * SCLzm(igrid,inf,1,1,beta,alpha)
     3                 - tF * C1LP0(1)
                  SC3zm(igrid,inf,1,2,beta,alpha) = 
     1                 SC3zm(igrid,inf,1,2,beta,alpha)
     2                 + tR * b0 * SC3zm(igrid,inf,1,1,beta,alpha)
     3                 - tF * C13P0(1)
     4                 + tF2h * ( P0P0(1)
     5                 - b0 * SP(igrid,inf,mapP(1,2),0,beta,alpha) )
     6                 / inf
     7                 - tF * SP(igrid,inf,mapP(1,2),1,beta,alpha) / inf
*     Pure-singlet
                  SC2zm(igrid,inf,2,2,beta,alpha) =
     1                 SC2zm(igrid,inf,2,2,beta,alpha)
     2                 - tF * C12P0(2)
     3                 + tF2h * P0P0(2) / inf
     4                 - tF * ( SP(igrid,inf,mapP(1,1),1,beta,alpha)
     5                 - SP(igrid,inf,1,1,beta,alpha) ) / inf
                  SCLzm(igrid,inf,2,2,beta,alpha) =
     1                 SCLzm(igrid,inf,2,2,beta,alpha)
     2                 - tF * C1LP0(2)
                  SC3zm(igrid,inf,2,2,beta,alpha) =
     1                 SC3zm(igrid,inf,2,2,beta,alpha)
     2                 - tF * C13P0(2)
     3                 + tF2h * P0P0(2) / inf
     3                 - tF * ( SP(igrid,inf,mapP(1,1),1,beta,alpha)
     4                 - SP(igrid,inf,1,1,beta,alpha) ) / inf
*     Plus
                  SC2zm(igrid,inf,3,2,beta,alpha) = 
     1                 SC2zm(igrid,inf,3,2,beta,alpha)
     2                 + tR * b0 * SC2zm(igrid,inf,3,1,beta,alpha)
     3                 - tF * C12P0(3)
     4                 + tF2h * ( P0P0(3)
     5                 - b0 * SP(igrid,inf,1,0,beta,alpha) )
     6                 - tF * SP(igrid,inf,1,1,beta,alpha)
                  SCLzm(igrid,inf,3,2,beta,alpha) = 
     1                 SCLzm(igrid,inf,3,2,beta,alpha)
     2                 + tR * b0 * SCLzm(igrid,inf,3,1,beta,alpha)
     3                 - tF * C1LP0(3)
                  SC3zm(igrid,inf,3,2,beta,alpha) = 
     1                 SC3zm(igrid,inf,3,2,beta,alpha)
     2                 + tR * b0 * SC3zm(igrid,inf,3,1,beta,alpha)
     3                 - tF * C13P0(3)
     4                 + tF2h * ( P0P0(3)
     5                 - b0 * SP(igrid,inf,1,0,beta,alpha) )
     6                 - tF * SP(igrid,inf,1,1,beta,alpha)
*     Minus
                  SC2zm(igrid,inf,4,2,beta,alpha) = 
     1                 SC2zm(igrid,inf,4,2,beta,alpha)
     2                 + tR * b0 * SC2zm(igrid,inf,4,1,beta,alpha)
     3                 - tF * C12P0(4)
     4                 + tF2h * ( P0P0(4)
     5                 - b0 * SP(igrid,inf,2,0,beta,alpha) )
     6                 - tF * SP(igrid,inf,2,1,beta,alpha)
                  SCLzm(igrid,inf,4,2,beta,alpha) = 
     1                 SCLzm(igrid,inf,4,2,beta,alpha)
     2                 + tR * b0 * SCLzm(igrid,inf,4,1,beta,alpha)
     3                 - tF * C1LP0(4)
                  SC3zm(igrid,inf,4,2,beta,alpha) = 
     1                 SC3zm(igrid,inf,4,2,beta,alpha)
     2                 + tR * b0 * SC3zm(igrid,inf,4,1,beta,alpha)
     3                 - tF * C13P0(4)
     4                 + tF2h * ( P0P0(4)
     5                 - b0 * SP(igrid,inf,2,0,beta,alpha) )
     6                 - tF * SP(igrid,inf,2,1,beta,alpha)
               enddo
            enddo
         endif
*
*     NLO
*
         do beta=0,gbound
            do alpha=beta,nin(igrid)-1
*     Gluon
               SC2zm(igrid,inf,1,1,beta,alpha) = 
     1              SC2zm(igrid,inf,1,1,beta,alpha)
     2              - tF * SP(igrid,inf,mapP(1,2),0,beta,alpha) / inf
               SC3zm(igrid,inf,1,1,beta,alpha) = 
     1              SC3zm(igrid,inf,1,1,beta,alpha)
     2              - tF * SP(igrid,inf,mapP(1,2),0,beta,alpha) / inf
*     Plus
               SC2zm(igrid,inf,3,1,beta,alpha) = 
     1              SC2zm(igrid,inf,3,1,beta,alpha)
     2              - tF * SP(igrid,inf,1,0,beta,alpha)
               SC3zm(igrid,inf,3,1,beta,alpha) = 
     1              SC3zm(igrid,inf,3,1,beta,alpha)
     2              - tF * SP(igrid,inf,1,0,beta,alpha)
*     Minus
               SC2zm(igrid,inf,4,1,beta,alpha) = 
     1              SC2zm(igrid,inf,4,1,beta,alpha)
     2              - tF * SP(igrid,inf,2,0,beta,alpha)
               SC3zm(igrid,inf,4,1,beta,alpha) = 
     1              SC3zm(igrid,inf,4,1,beta,alpha)
     2              - tF * SP(igrid,inf,2,0,beta,alpha)
            enddo
         enddo
      enddo
*
      ipt_FF = ipt
      if(MassScheme.eq."FONLL-B".and.ipt.ge.1) ipt_FF = 2
*
*     If the dynamical scale variation has been chosen, the analytical
*     factorization scale terms, that would already be present at the
*     initialization stage, have been set to zero and must be computed
*     numerically here and added to the non-scale terms. Otherwise only
*     the renormalization scale dependente terms need to be included.
*
      if(DynScVar)then
*
*     FFNS
*
         if(MassScheme(1:4).eq."FFNS".or.
     1      MassScheme(1:5).eq."FONLL")then
*
*     Neutral Current
*
            if(ipt_FF.ge.2)then
               b0 = beta0apf(Nf_FF)
               do beta=0,gbound
                  do alpha=beta,nin(igrid)-1
                     do inf=4,6
                        do jxi=ixi(inf),ixi(inf)+1
                           if(ixi(inf).eq.0) cycle
*
*     Precompute needed convolutions
*
                           do k=1,2
                              C12P0(k) = 0d0
                              C1LP0(k) = 0d0
                           enddo
*
*     External grid
*
                           if(IsExt(igrid))then
                              do gamma=beta,alpha
*     Gluon
                                 C12P0(1) = C12P0(1)
     4                         + SC2mNC(igrid,jxi,mapC(2),1,beta,gamma)
     5                         * SP(igrid,Nf_FF,mapP(2,2),0,gamma,alpha)
                                 C1LP0(1) = C1LP0(1)
     4                         + SCLmNC(igrid,jxi,mapC(2),1,beta,gamma)
     5                         * SP(igrid,Nf_FF,mapP(2,2),0,gamma,alpha)
*     Pure-singlet
                                 C12P0(2) = C12P0(2)
     1                         + SC2mNC(igrid,jxi,mapC(2),1,beta,gamma)
     2                         * SP(igrid,Nf_FF,mapP(2,1),0,gamma,alpha)
                                 C1LP0(2) = C1LP0(2)
     1                         + SCLmNC(igrid,jxi,mapC(2),1,beta,gamma)
     2                         * SP(igrid,Nf_FF,mapP(2,1),0,gamma,alpha)
                              enddo
*
*     Internal grid
*
                           else
                              do gamma=beta,alpha
*     Gluon
                                 C12P0(1) = C12P0(1)
     4                       + SC2mNC(igrid,jxi,mapC(2),1,0,gamma-beta)
     5                       * SP(igrid,Nf_FF,mapP(2,2),0,0,alpha-gamma)
                                 C1LP0(1) = C1LP0(1)
     4                       + SCLmNC(igrid,jxi,mapC(2),1,0,gamma-beta)
     5                       * SP(igrid,Nf_FF,mapP(2,2),0,0,alpha-gamma)
*     Pure-singlet
                                 C12P0(2) = C12P0(2)
     1                       + SC2mNC(igrid,jxi,mapC(2),1,0,gamma-beta)
     2                       * SP(igrid,Nf_FF,mapP(2,1),0,0,alpha-gamma)
                                 C1LP0(2) = C1LP0(2)
     1                       + SCLmNC(igrid,jxi,mapC(2),1,0,gamma-beta)
     2                       * SP(igrid,Nf_FF,mapP(2,1),0,0,alpha-gamma)
                              enddo
                           endif
*
                           do k=1,2
                              SC2mNC(igrid,jxi,k,2,beta,alpha) = 
     1                             SC2mNC(igrid,jxi,k,2,beta,alpha)
     2                             + tR * b0
     3                             * SC2mNC(igrid,jxi,k,1,beta,alpha)
     4                             - tF * C12P0(k)
                              SCLmNC(igrid,jxi,k,2,beta,alpha) = 
     1                             SCLmNC(igrid,jxi,k,2,beta,alpha)
     2                             + tR * b0
     3                             * SCLmNC(igrid,jxi,k,1,beta,alpha)
     4                             - tF * C1LP0(k)
                           enddo
                        enddo
                     enddo
                  enddo
               enddo
            endif
*
*     Charged Current
*     (Correct only NLO terms)
*
            do beta=0,gbound
               do alpha=beta,nin(igrid)-1
                  do inf=4,6
                     do jxi=ixi(inf),ixi(inf)+1
                        if(ixi(inf).eq.0) cycle
                        omlam = 1d0 / ( 1d0 + xigrid(jxi*xistep) )
*     Gluon
                        SC2mCC(igrid,jxi,1,1,beta,alpha) = 
     1                       SC2mCC(igrid,jxi,1,1,beta,alpha) - tF
     2                       * SP(igrid,Nf_FF,mapP(1,2),0,beta,alpha)
     3                       / Nf_FF / 2d0
                        SCLmCC(igrid,jxi,1,1,beta,alpha) = 
     1                       SCLmCC(igrid,jxi,1,1,beta,alpha) - tF
     2                       * SP(igrid,Nf_FF,mapP(1,2),0,beta,alpha)
     3                       / Nf_FF  / 2d0 * omlam
                        SC3mCC(igrid,jxi,1,1,beta,alpha) = 
     1                       SC3mCC(igrid,jxi,1,1,beta,alpha) - tF
     2                       * SP(igrid,Nf_FF,mapP(1,2),0,beta,alpha)
     3                       / Nf_FF / 2d0
*     Plus
                        SC2mCC(igrid,jxi,3,1,beta,alpha) = 
     1                       SC2mCC(igrid,jxi,3,1,beta,alpha) - tF
     2                       * SP(igrid,Nf_FF,1,0,beta,alpha)
                        SCLmCC(igrid,jxi,3,1,beta,alpha) = 
     1                       SCLmCC(igrid,jxi,3,1,beta,alpha) - tF
     2                       * SP(igrid,Nf_FF,1,0,beta,alpha) * omlam
                        SC3mCC(igrid,Nf_FF,3,1,beta,alpha) = 
     1                       SC3mCC(igrid,jxi,3,1,beta,alpha) - tF
     2                       * SP(igrid,Nf_FF,1,0,beta,alpha)
                     enddo
                  enddo
               enddo
            enddo
         endif
*
*     FFN0
*
         if(MassScheme(1:4).eq."FFN0".or.
     1      MassScheme(1:5).eq."FONLL")then
*
*     Neutral Current
*
            if(ipt_FF.ge.2)then
               b0 = beta0apf(Nf_FF)
               do beta=0,gbound
                  do alpha=beta,nin(igrid)-1
                     do inf=4,6
                        do jxi=ixi(inf),ixi(inf)+1
                           if(ixi(inf).eq.0) cycle
*
*     Precompute needed convolutions
*
                           do k=1,2
                              C12P0(k) = 0d0
                              C1LP0(k) = 0d0
                           enddo
*
*     External grid
*
                           if(IsExt(igrid))then
                              do gamma=beta,alpha
*     Gluon
                                 C12P0(1) = C12P0(1)
     1                         + SC2m0NC(igrid,jxi,mapC(2),1,beta,gamma)
     2                         * SP(igrid,Nf_FF,mapP(2,2),0,gamma,alpha)
                                 C1LP0(1) = C1LP0(1)
     1                         + SCLm0NC(igrid,jxi,mapC(2),1,beta,gamma)
     2                         * SP(igrid,Nf_FF,mapP(2,2),0,gamma,alpha)
*     Pure-singlet
                                 C12P0(2) = C12P0(2)
     1                         + SC2m0NC(igrid,jxi,mapC(2),1,beta,gamma)
     2                         * SP(igrid,Nf_FF,mapP(2,1),0,gamma,alpha)
                                 C1LP0(2) = C1LP0(2)
     1                         + SCLm0NC(igrid,jxi,mapC(2),1,beta,gamma)
     2                         * SP(igrid,Nf_FF,mapP(2,1),0,gamma,alpha)
                              enddo
*
*     Internal grid
*
                           else
                              do gamma=beta,alpha
*     Gluon
                                 C12P0(1) = C12P0(1)
     1                       + SC2m0NC(igrid,jxi,mapC(2),1,0,gamma-beta)
     2                       * SP(igrid,Nf_FF,mapP(2,2),0,0,alpha-gamma)
                                 C1LP0(1) = C1LP0(1)
     1                       + SCLm0NC(igrid,jxi,mapC(2),1,0,gamma-beta)
     2                       * SP(igrid,Nf_FF,mapP(2,2),0,0,alpha-gamma)
*     Pure-singlet
                                 C12P0(2) = C12P0(2)
     1                       + SC2m0NC(igrid,jxi,mapC(2),1,0,gamma-beta)
     2                       * SP(igrid,Nf_FF,mapP(2,1),0,0,alpha-gamma)
                                 C1LP0(2) = C1LP0(2)
     1                       + SCLm0NC(igrid,jxi,mapC(2),1,0,gamma-beta)
     2                       * SP(igrid,Nf_FF,mapP(2,1),0,0,alpha-gamma)
                              enddo
                           endif
*
                           do k=1,2
                              SC2m0NC(igrid,jxi,k,2,beta,alpha) = 
     1                             SC2m0NC(igrid,jxi,k,2,beta,alpha)
     2                             + tR * b0
     3                             * SC2m0NC(igrid,jxi,k,1,beta,alpha)
     4                             - tF * C12P0(k)
                              SCLm0NC(igrid,jxi,k,2,beta,alpha) = 
     1                             SCLm0NC(igrid,jxi,k,2,beta,alpha)
     2                             + tR * b0
     3                             * SCLm0NC(igrid,jxi,k,1,beta,alpha)
     4                             - tF * C1LP0(k)
                           enddo
                        enddo
                     enddo
                  enddo
               enddo
            endif
*
*     Charged Current
*     (Correct only NLO terms)
*
            do beta=0,gbound
               do alpha=beta,nin(igrid)-1
                  do inf=4,6
                     do jxi=ixi(inf),ixi(inf)+1
                        if(ixi(inf).eq.0) cycle
*     Gluon
                        SC2m0CC(igrid,jxi,1,1,beta,alpha) = 
     1                       SC2m0CC(igrid,jxi,1,1,beta,alpha) - tF
     2                       * SP(igrid,Nf_FF,mapP(1,2),0,beta,alpha)
     3                       / Nf_FF / 2d0
                        SC3m0CC(igrid,jxi,1,1,beta,alpha) = 
     1                       SC3m0CC(igrid,jxi,1,1,beta,alpha) - tF
     2                       * SP(igrid,Nf_FF,mapP(1,2),0,beta,alpha)
     3                       / Nf_FF / 2d0
*     Plus
                        SC2m0CC(igrid,jxi,3,1,beta,alpha) = 
     1                       SC2m0CC(igrid,jxi,3,1,beta,alpha) - tF
     2                       * SP(igrid,Nf_FF,1,0,beta,alpha)
                        SC3m0CC(igrid,Nf_FF,3,1,beta,alpha) = 
     1                       SC3m0CC(igrid,jxi,3,1,beta,alpha) - tF
     2                       * SP(igrid,Nf_FF,1,0,beta,alpha)
                     enddo
                  enddo
               enddo
            enddo
         endif
      else
*
*     FFNS
*
         if(MassScheme(1:4).eq."FFNS".or.
     1      MassScheme(1:5).eq."FONLL")then
            if(ipt_FF.ge.2)then
               b0 = beta0apf(Nf_FF)
               do beta=0,gbound
                  do alpha=beta,nin(igrid)-1
                     do jxi=1,nxir
                        do k=1,2
                           SC2mNC(igrid,jxi,k,2,beta,alpha) = 
     1                          SC2mNC(igrid,jxi,k,2,beta,alpha)
     2                          + ( tR - tF ) * b0
     3                          * SC2mNC(igrid,jxi,k,1,beta,alpha)
                           SCLmNC(igrid,jxi,k,2,beta,alpha) = 
     1                          SCLmNC(igrid,jxi,k,2,beta,alpha)
     2                          + ( tR - tF ) * b0
     3                          * SCLmNC(igrid,jxi,k,1,beta,alpha)
                        enddo
                     enddo
                  enddo
               enddo
            endif
         endif
*
*     FFN0
*
         if(MassScheme(1:4).eq."FFN0".or.
     1      MassScheme(1:5).eq."FONLL")then
            if(ipt_FF.ge.2)then
               b0 = beta0apf(Nf_FF)
               do beta=0,gbound
                  do alpha=beta,nin(igrid)-1
                     do jxi=1,nxir
                        do k=1,2
                           SC2m0NC(igrid,jxi,k,2,beta,alpha) = 
     1                          SC2m0NC(igrid,jxi,k,2,beta,alpha)
     2                          + ( tR - tF ) * b0
     3                          * SC2m0NC(igrid,jxi,k,1,beta,alpha)
                           SCLm0NC(igrid,jxi,k,2,beta,alpha) = 
     1                          SCLm0NC(igrid,jxi,k,2,beta,alpha)
     2                          + ( tR - tF ) * b0
     3                          * SCLm0NC(igrid,jxi,k,1,beta,alpha)
                        enddo
                     enddo
                  enddo
               enddo
            endif
         endif
      endif
*
      return
      end
