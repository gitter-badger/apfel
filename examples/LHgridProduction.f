************************************************************************
*
*     Example program that produces an LHgrid file
*
************************************************************************
      program LHgridProduction
*
      implicit none
*
      double precision Qin
*
      call SetPerturbativeOrder(1)
      call SetAlphaQCDRef(0.118d0,91.d0)
      call SetPoleMasses(1.275d0,4.18d0,173.07d0)
      call SetMaxFlavourPDFs(5)
      call SetMaxFlavourAlpha(5)
      call SetPDFset("NNPDF30_nlo_as_0118.LHgrid")
*
      Qin = dsqrt(1d0)
      call LHAPDFgrid(100,Qin,"apfel_nn30nlo118_dire")
*
      end
