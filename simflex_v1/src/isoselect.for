      ! calculates isoline of normcorcoef respective to Threschprob
      subroutine isoselect()
      use SIMFLEX,only:Niso,Isolines,Prob_iso,Threshprob,iso1
      implicit none
      integer k

      iso1=0
      do k=Niso,1,-1
        if(Prob_iso(k).ge.Threshprob)then
          iso1=Isolines(k)
        endif
      enddo
      if(iso1.eq.0)then
        write(6,*)'Warning from isoselect: the smallest possible'
        write(6,*)'isoline=',Isolines(1),'corresponds to probability',
     &             ' of source location=',Prob_iso(1)
        write(6,*)'that is less than specified probability Threshprob=',
     &            Threshprob
         write(6,*)'Masses of release will be calculated for cells'
          write(6,*)'corresponding to region with the respective'
          write(6,*)'largest possible probability=',Prob_iso(1)
          write(6,*)'Alternatively number of isolines in Isolines'
          write(6,*)'array as input by user, should be increased'
          write(6,*)' '

          iso1=Isolines(1)
       endif

        write(6,*)'Result of isoselect:'
        write(6,*)'release start time, duration and mass will'
        write(6,*)'be evaluated in cells with normalized corr. coef. '
        write(6,*)'greater or equal than iso1=',iso1
        write(6,*)' '
      end subroutine
