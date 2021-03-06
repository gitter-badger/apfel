************************************************************************
*
*     LHAPDFgridDerivative.f:
*
*     If LHAPDF5 is found, this subrotine produces the *.LHgrid file
*     that can be used with LHAPDF v5.9. If instead LHAPDF6 is found
*     a folder contained the PDF set in a suitable format is produced.
*
************************************************************************
      subroutine LHAPDFgridDerivative(Nrep,fname)
*
      implicit none
*
      include "../commons/grid.h"
      include "../commons/ipt.h"
      include "../commons/alpha_ref_QCD.h"
      include "../commons/m2th.h"
      include "../commons/kren.h"
      include "../commons/Th.h"
      include "../commons/LHAgrid.h"
      include "../commons/Evs.h"
      include "../commons/MaxFlavourPDFs.h"
      include "../commons/MaxFlavourAlpha.h"
      include "../commons/LeptEvol.h"
      include "../commons/Nf_FF.h"
      include "../commons/pdfset.h"
      include "../commons/f0ph.h"
**
*     Input Variables
*
      integer Nrep
      logical islhapdf6
      character*50 fname
**
*     Intenal Variables
*
      integer ln
      integer i,ix,iq2,iq2c,ipdf,ilep,krep,iq2in,iq2fi
      integer nfin,nffi
      integer isg,nQ(3:7)
      integer nfmax
      integer alpha
      double precision qref,mth(4:6)
      double precision lambda3,lambda4,lambda5,lambdaNF
      double precision xbLHA(nxmax),q2LHA(nq2max)
      double precision lnQmin,lnQmax
      double precision eps,eps2,offset
      double precision xpdfLHA(-6:6,nxmax,nq2max)
      double precision xgammaLHA(nxmax,nq2max)
      double precision xlepLHA(-6:6,nxmax,nq2max)
      double precision dxPDF,dxgamma
      double precision AlphaQCD
      character*30  str
      parameter(eps=1d-4)
      parameter(eps2=1d-12)
      parameter(offset=1d-2)
*
      double precision fqpre1(ngrid_max,-6:6,0:nint_max)
      double precision flpre1(ngrid_max,-3:3,0:nint_max)
      common / pretab1APFEL / fqpre1,flpre1
*
*     Specify initialization for the LHgrid
*
      if(InLHgrid.ne."done") call SetLHgridParameters(100,50,1d-9,1d-1,
     1                                                1d0,50,1d0,1d10)
      call SetQLimits(dsqrt(q2minLHA)-offset,dsqrt(q2maxLHA)+offset)
      call SetNumberOfGrids(3)
      call SetGridParameters(1,150,3,xminLHA)
      call SetGridParameters(2,100,5,xmLHA)
      call SetGridParameters(3,100,5,0.65d0)
      call LockGrids(.true.)
*
*     Initialize APFEL
*
      Call initializeAPFEL
*
*     Report grid parameters
*
      write(6,*) "Report of the LHAPDF grid parameters:"
      write(6,"(a,i3,a,f11.9,a,f6.4,a)") " - x-space grid: ",nxLHA,
     1     " points in [",xminLHA," :",xmaxLHA,"]"
      write(6,"(a,f6.4)") "    transition from log to lin in x = ",xmLHA
      write(6,"(a,i3,a,f5.2,a,f13.1,a)") " - Q2-space grid: ",nq2LHA,
     1     " points in [",q2minLHA,":",q2maxLHA,"] GeV^2"
      write(6,*) " "
*
*     Compute the values of lambdaQCD
*
      lambda5 = lambdaNF(5,alpha_ref_qcd,q2_ref_qcd)
      lambda4 = lambdaNF(4,alpha_ref_qcd,q2_ref_qcd)
      lambda3 = lambdaNF(3,alpha_ref_qcd,q2_ref_qcd)
*
*     Define maximun number of flavours
*
      nfmax = max(nfMaxPDFs,nfMaxAlpha)
*
*     Compute x-space grid
*
      do ix=1,nxLHA
         if(ix.le.nxmLHA)then
            xbLHA(ix) = xminLHA * ( xmLHA / xminLHA )
     1                **( 2d0 * dble( ix-1 ) / dble( nxLHA - 1 ) )
         else
            xbLHA(ix) = xmLHA + ( xmaxLHA - xmLHA )
     1                * ( dble( ix - nxmLHA - 1 )
     2                / dble( nxLHA - nxmLHA - 1 ) )
         endif
      enddo
*
*     Compute Q2 grid.
*     Use a distribution of the Q2 nodes uniform in ln(ln(Q2/Lambda2))
*     and that has nodes on the heavy quark thresholds.
*
      lnQmin = dlog( q2minLHA / Lambda2 )
      lnQmax = dlog( q2maxLHA / Lambda2 )
*
      if(Evs.eq."VF")then
         if(q2minLHA.gt.m2th(6))then
            nfin = 6
         elseif(q2minLHA.gt.m2th(5))then
            nfin = 5
         elseif(q2minLHA.gt.m2th(4))then
            nfin = 4
         else
            nfin = 3
         endif
         if(nfin.gt.nfmax) nfin = nfmax
*
         if(q2maxLHA.gt.m2th(6))then
            nffi = 6
         elseif(q2maxLHA.gt.m2th(5))then
            nffi = 5
         elseif(q2maxLHA.gt.m2th(4))then
            nffi = 4
         else
            nffi = 3
         endif
         if(nffi.gt.nfmax) nffi = nfmax
*
*     Number of points per subgrid
*
         do isg=3,7
            nQ(isg) = 0
         enddo
*
         isg = nfin
         do iq2=1,nq2LHA
            q2LHA(iq2) = Lambda2 * dexp( lnQmin
     1                 * dexp( dble( iq2 - 1 ) / dble( nq2LHA - 1 )
     2                 * dlog( lnQmax / lnQmin ) ) )
            if(q2LHA(iq2).lt.m2th(isg+1)+eps)then
               nQ(isg) = nQ(isg) + 1
            else
               isg = isg + 1
               if(isg.gt.nfmax) isg = nfmax
               nQ(isg) = nQ(isg) + 1
            endif
         enddo
*
*     If the LHAPDF6 format is to be used redefine the grid with the subgrids
*
         if(islhapdf6())then
            lnQmin = dlog( ( q2minLHA ) / Lambda2 )
            if(nfin.eq.nffi)then
               lnQmax = dlog( q2maxLHA / Lambda2 )
            else
               lnQmax = dlog( ( m2th(nfin+1) ) / Lambda2 )
            endif
*
            iq2c = 0
            do isg=nfin,nffi
               do iq2=1,nQ(isg)
                  iq2c = iq2c + 1
                  q2LHA(iq2c) = Lambda2 * dexp( lnQmin
     1                        * dexp( dble( iq2 - 1 )
     2                        / dble( nQ(isg) - 1 )
     3                        * dlog( lnQmax / lnQmin ) ) )
               enddo
               lnQmin = dlog( ( q2LHA(iq2c) ) / Lambda2 )
               if(isg.eq.nffi-1)then
                  lnQmax = dlog( q2maxLHA / Lambda2 )
               else
                  lnQmax = dlog( ( m2th(isg+2) ) / Lambda2 )
               endif
            enddo
*
            if(iq2c.ne.nq2LHA)then
               write(6,*) "In LHAPDFgrid.f:"
               write(6,*) "Mismatch in the Number of Q2 nodes"
               write(6,*) "- Expected = ",nq2LHA
               write(6,*) "- Found = ",iq2c
               call exit(-10)
            endif
         endif
      else
         nQ(Nf_FF) = nq2LHA
         nfin      = Nf_FF
         nffi      = Nf_FF
         do iq2=1,nq2LHA
            q2LHA(iq2) = Lambda2 * dexp( lnQmin
     1                 * dexp( dble( iq2 - 1 ) / dble( nq2LHA - 1 )
     2                 * dlog( lnQmax / lnQmin ) ) )
         enddo
      endif
*
*     LHAPDF5 output
*
      if(.not.islhapdf6())then
*
*     Open the output file
*
         ln = index(fname,char(0)) - 1
         if(ln.eq.-1) ln = index(fname,char(32)) - 1
         open(unit=13,status="unknown",file=fname(1:ln)//".LHgrid")
*
*     Write header
*
         write(13,*) "'Version'"," '5.8.9'"
         write(13,*) "'Description: set generated with APFEL'"
         write(13,*) "'",fname(1:ln),".LHgrid'"
         write(13,*) "'Reference: arXiv:1310.1394'"
         write(13,*) "'APFEL: A PDF Evolution Library'"
         write(13,*) "'V. Bertone, S. Carrazza, J. Rojo'"
         write(13,*)"' ***********************'"
         write(13,*)"' *** PDF DERIVATIVES ***'"
         write(13,*)"' ***********************'"
         write(13,*) "'This set has ",Nrep," member PDF'"
         write(13,*) "'mem=0 --> average on replicas. '"
         write(13,*) "'Evolution: pol. interpolation on the LH grid.'"
*
         write(13,*) "'Alphas:'"
         if(ipt.eq.0)then
            write(13,*) "'Variable',","'lo',","'EvolCode'"
         elseif(ipt.eq.1)then
            write(13,*) "'Variable',","'nlo',","'EvolCode'"
         elseif(ipt.eq.2)then
            write(13,*) "'Variable',","'nnlo',","'EvolCode'"
         endif
*
         qref = dsqrt(q2_ref_qcd)
         do i=4,6
            mth(i) = dsqrt(m2th(i))
         enddo
*
         write(13,*) 1,",",qref,",",mth(4),",",mth(5),",",mth(6)
*
         write(13,*) "'MinMax:'"
         write(13,*) Nrep,",",1
         write(13,*) xminLHA,",",xmaxLHA,",",q2minLHA,",",q2maxLHA
*
         write(13,*) "'QCDparams:'"
         write(13,*) Nrep,",",1
         write(13,*) lambda4,",",lambda5
*
         write(13,*) "'Parameterlist:'"
         write(13,*) "'list',",Nrep,",",1
*
         do i=0,Nrep
            write(13,*) alpha_ref_qcd
         enddo
*
         write(13,* ) "'Evolution:'"
         if(ipt.eq.0)then
            write(13,*) "'lo',",q2minLHA,",",kren
         elseif(ipt.eq.1)then
            write(13,*) "'nlo',",q2minLHA,",",kren
         elseif(ipt.eq.2)then
            write(13,*) "'nnlo',",q2minLHA,",",kren
         endif
         if(Th.eq."QCD")then
            write(13,*) "'NNPDF20int'"
         else
            write(13,*) "'NNPDF20intqed'"
         endif
         write(13,*) Nrep,",",1
*
*     Compute and write the grids in x and Q2
*
         write(13,*) nxLHA
         do ix=1,nxLHA
            write(13,*) xbLHA(ix)
         enddo
*
         write(13,*) nq2LHA
         write(13,*) q2minLHA
         do iq2=1,nq2LHA
            write(13,*) q2LHA(iq2)
         enddo
*
*     Compute derivarive and write it on file
*
         write(13,*) Nrep
         do krep=0,Nrep
            write(6,*) "Evaluating replica",krep," ..."
            call SetReplica(krep)
            do iq2=1,nq2LHA
               call DeriveAPFEL(dsqrt(q2LHA(iq2)))
               do ix=1,nxLHA
                  do ipdf=-6,6
                     xpdfLHA(ipdf,ix,iq2) = dxPDF(ipdf,xbLHA(ix))
                  enddo
                  xgammaLHA(ix,iq2) = dxgamma(xbLHA(ix))
               enddo
            enddo
*
            if(Th.eq."QCD")then
               do ix=1,nxLHA
                  do iq2=1,nq2LHA
                     write(13,44) (xpdfLHA(ipdf,ix,iq2),ipdf=-6,6)
                  enddo
               enddo
            else
               do ix=1,nxLHA
                  do iq2=1,nq2LHA
                     write(13,45) (xpdfLHA(ipdf,ix,iq2),ipdf=-6,6),
     1                             xgammalha(ix,iq2)
                  enddo
               enddo
            endif
         enddo
*
         write(13,* ) "'End:'"
         close(13)
*
         write(6,*) "File ",fname(1:ln),".LHgrid produced!"
         write(6,*) "  "
      else
*
*     LHAPDF6 output
*
         ln = index(fname,char(0)) - 1
         if(ln.eq.-1) ln = index(fname,char(32)) - 1
*     creating main folder
         call mkdir(fname(1:ln))
*     creating info file
         open(unit=13,status="unknown",file=fname(1:ln)//"/"
     1        //fname(1:ln)//".info")
*
*     Write header
*
         write(13,*) "SetDesc: set generated with APFEL - ",fname(1:ln)
         write(13,*) "Authors: V. Bertone, S. Carrazza, J. Rojo"
         write(13,*) "Reference: ArXiv:1310.1394"
         write(13,*) "Format: lhagrid1"
         write(13,*) "DataVersion: 1"
         write(13,*) "NumMembers:",Nrep+1
         write(13,*) "Particle: 2212"
         if(Th.eq."QCD") then
            write(13,*) "Flavors: [-6, -5, -4, -3, -2, -1,",
     1                  "21, 1, 2, 3, 4, 5, 6]"
         else
            if(LeptEvol)then
               write(13,*) "Flavors: [-6, -5, -4, -3, -2, -1, 21,",
     1                               " 1, 2, 3, 4, 5, 6, 22, ",
     2                               "11, -11, 13, -13, 15, -15]"
            else
               write(13,*) "Flavors: [-6, -5, -4, -3, -2, -1, 21,",
     1                               " 1, 2, 3, 4, 5, 6, 22]"
            endif
         endif
         write(13,*) "OrderQCD:",ipt
         write(13,*) "FlavorScheme: variable"
         write(13,*) "NumFlavors: 6"
         write(13,*) "ErrorType: replicas"
         write(13,*) "XMin:", xminLHA
         write(13,*) "XMax:", xmaxLHA
         write(13,*) "QMin:", dsqrt(q2minLHA)
         write(13,*) "QMax:", dsqrt(q2maxLHA)
         write(13,*) "MZ:",dsqrt(q2_ref_qcd)
         write(13,*) "MUp: 0"
         write(13,*) "MDown: 0"
         write(13,*) "MStrange: 0"
         write(13,*) "MCharm:",dsqrt(m2th(4))
         write(13,*) "MBottom:",dsqrt(m2th(5))
         write(13,*) "MTop:",dsqrt(m2th(6))
         write(13,*) "AlphaS_MZ:",alpha_ref_qcd
         write(13,*) "AlphaS_OrderQCD:",ipt
         write(13,*) "AlphaS_Type: ipol"
         write(13,*)"AlphaS_Qs: [",(dsqrt(q2LHA(iq2)),",",iq2=1,nq2LHA),
     1              "]"
         write(13,*) "AlphaS_Vals: [",(AlphaQCD(dsqrt(q2LHA(iq2))),
     1               ",",iq2=1,nq2LHA), "]"
         write(13,*) "AlphaS_Lambda4:", lambda4
         write(13,*) "AlphaS_Lambda5:", lambda5
         close(13)
*
*     Now Loop over all replicas and print to file
*
         do krep=0,Nrep
            if (krep.lt.10) then
               write(str,'(i1)' ) krep
               open(unit=13,status="unknown",file=fname(1:ln)//"/"
     1              //fname(1:ln)//"_000"//str(1:1)//".dat")
            elseif (krep.lt.100) then
               write(str,'(i2)' ) krep
               open(unit=13,status="unknown",file=fname(1:ln)//"/"
     1              //fname(1:ln)//"_00"//str(1:2)//".dat")
            elseif (krep.lt.1000) then
               write(str,'(i3)' ) krep
               open(unit=13,status="unknown",file=fname(1:ln)//"/"
     1              //fname(1:ln)//"_0"//str(1:3)//".dat")
            else
               write(str,'(i4)' ) krep
               open(unit=13,status="unknown",file=fname(1:ln)//"/"
     1              //fname(1:ln)//"_"//str(1:4)//".dat")
            endif
            if (krep.eq.0) then
               write(13,*) "PdfType: central"
            else
               write(13,*) "PdfType: replica"
            endif
            write(13,*) "Format: lhagrid1"
            write(13,*) "---"
*
            write(6,*) "Evaluating replica",krep," ..."
            call SetReplica(krep)
*
            iq2in = 1
            iq2fi = nQ(nfin)
            do isg=nfin,nffi
               write(13,*) (xbLHA(ix),ix=1,nxLHA)
               write(13,*) (dsqrt(q2LHA(iq2)), iq2=iq2in,iq2fi)
*
               if(Th.eq."QCD") then
                  write(13,"(a)") "-6 -5 -4 -3 -2 -1 21 1 2 3 4 5 6"
               else
                  if(LeptEvol)then
                     write(13,"(a,a,a)") "-6 -5 -4 -3 -2 -1 21",
     1                                   " 1 2 3 4 5 6 22 ",
     2                                   "11 -11 13 -13 15 -15"
                  else
                     write(13,"(a,a)") "-6 -5 -4 -3 -2 -1 21",
     1                               " 1 2 3 4 5 6 22"
                  endif
               endif
*
               do iq2=iq2in,iq2fi
                  if(iq2.eq.iq2in.and.isg.ne.nfin)then
                     call DeriveAPFEL(dsqrt(q2LHA(iq2)+eps2))
                  elseif(iq2.eq.iq2fi.and.isg.ne.nffi)then
                     call DeriveAPFEL(dsqrt(q2LHA(iq2)-eps2))
                  else
                     call DeriveAPFEL(dsqrt(q2LHA(iq2)))
                  endif
                  do ix=1,nxLHA
                     do ipdf=-6,6
                        xpdfLHA(ipdf,ix,iq2) = dxPDF(ipdf,xbLHA(ix))
                     enddo
                     do ilep=-3,3
                        xlepLHA(ilep,ix,iq2) = 0d0
                     enddo
                     xgammaLHA(ix,iq2) = dxgamma(xbLHA(ix))
                  enddo
               enddo
*
               if(Th.eq."QCD")then
                  do ix=1,nxLHA
                     do iq2=iq2in,iq2fi
                        write(13,44) (xpdfLHA(ipdf,ix,iq2),ipdf=-6,6)
                     enddo
                  enddo
               else
                  if(LeptEvol)then
                     do ix=1,nxLHA
                        do iq2=iq2in,iq2fi
                           write(13,46)(xpdfLHA(ipdf,ix,iq2),ipdf=-6,6),
     1                                  xgammaLHA(ix,iq2),
     2                                  xlepLHA(1,ix,iq2),
     3                                  xlepLHA(-1,ix,iq2),
     4                                  xlepLHA(2,ix,iq2),
     5                                  xlepLHA(-2,ix,iq2),
     6                                  xlepLHA(3,ix,iq2),
     7                                  xlepLHA(-3,ix,iq2)
                        enddo
                     enddo
                  else
                     do ix=1,nxLHA
                        do iq2=iq2in,iq2fi
                           write(13,45)(xpdfLHA(ipdf,ix,iq2),ipdf=-6,6),
     1                                  xgammaLHA(ix,iq2)
                        enddo
                     enddo
                  endif
               endif
               write(13,*) "---"
               iq2in = iq2in + nQ(isg)
               iq2fi = iq2fi + nQ(isg+1)
            enddo
            close(13)
         enddo
*
         write(6,*) "File ",fname(1:ln)," grid produced!"
         write(6,*) "  "
      endif
*
 44   format(13(1x,es14.7))
 45   format(14(1x,es14.7))
 46   format(20(1x,es14.7))
*
      return
      end
