! evaluates in every grid node correlation coefficient of model vs obs
! obtained assuming continuous release with constant  rate in the respective node
!present implementation only for sources at single vertical level (single vertical level in srs)
      subroutine eval_srcloc()
      use SIMFLEX,only:Nobs,Obs_val1,AllSRS,MaxCor0,Imax0,
     &Jmax0,normcor0,nlon,nlat,MAXOBS,gridcells,lon,lat,
     &Niso,Prob_iso,Isolines,normcorname,ifdebug_out,
     &normcor_debug,calc_output_path
     
      implicit none
      integer i,j,k
      real Slice(MAXOBS),cor
      
       write(6,*)'From eval_srcloc:'
       write(6,*)'Evaluating regions of source locations'
       write(6,*)'by calculting corr. coef. of model vs obs'
       write(6,*)'assuming continuous release with constant rate'
       write(6,*)' in the respective node'
      
      allocate(normcor0(nlon,nlat))
      normcor0=0
      MaxCor0=0;
      
!calculate correlation
      do j=1,nlat
       do i=1,nlon
         do k=1,Nobs
           Slice(k)=AllSRS(k)%srstsum(i,j,1) !!present implementation only for sources at single vertical level (single vertical level in srs represented by 3d index=1)
         enddo
            call corcoef(Slice,Obs_val1,Nobs,cor)
            if(cor.lt.0)cor=0
            
            normcor0(i,j)=cor
            
            if(cor.gt.MaxCor0)then
              MaxCor0=cor
              Imax0=i
              Jmax0=j
            endif
         
       enddo
      enddo
!IK2023:
      if(MaxCor0.le.0.01)then
         write(6,*)'error4 from SIMFLEX:'
         write(6,*)'MaxCor=',MaxCor0,'is too low. No source in the'
         write(6,*)'domain could explain the observed values'
         stop
      endif

      normcor0=normcor0/MaxCor0

      write(6,*)'MaxCor0=',MaxCor0

!evaluate of probabilities of solurce location in regions within isolines of normcor0
      call eval_probloc(Niso,Prob_Iso,Isolines,normcor0,nlon,nlat)


! output results
       open(1110, FILE = calc_output_path // normcorname)
       if(ifdebug_out)open(1111,FILE=calc_output_path
     &              //normcor_debug)
       write(1111,*)'cell_id,lon,lat,normcor'
       k=0
       do j=1,nlat
       do i=1,nlon
          k=k+1
          if(ifdebug_out)write(1111,*)
     &                   gridcells(i,j),lon(i),lat(j),normcor0(i,j)
     
          write(1110,'(F8.6)') normcor0(i,j)
       enddo
       enddo
       if(ifdebug_out)close(1111)
       close(1110)
      
       open(1111, FILE=calc_output_path // 'maxcor.txt')
       write(1111,'(F4.2)') MaxCor0
       close(1111)

       open(1112, FILE=calc_output_path // 'Table.txt')
       do k=1,Niso
        write(1112,'(F4.2, F5.2)') Isolines(k), Prob_iso(k)
       enddo
       close(1112)

       write(6,*)' '

       continue

      end subroutine  eval_srcloc
      
      subroutine eval_probloc(Niso,Prob_Iso,Isolines,normcor0,nlon,nlat)
!evaluate of probabilities of solurce location in regions within given isolines of normcor0     
      implicit none
      integer Niso
      real Prob_iso(Niso)
      real Isolines(Niso)
      integer nlon,nlat
      real normcor0(nlon,nlat)
      
      integer i,j,k
      real SumAll
      
      SumAll=sum(normcor0(1:nlon,1:nlat))
      do j=1,nlat
        do i=1,nlon
          do k=1,Niso
             if(normcor0(i,j).ge.Isolines(k))then
               Prob_iso(k)=Prob_iso(k)+normcor0(i,j)
             endif
          enddo
        enddo
      enddo
      Prob_iso=Prob_iso/SumAll

      end subroutine eval_probloc
