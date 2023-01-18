! evaluates corr. coef/ for current start time and duration of release
! represented by the respective indices
! icell is number of subgrid cell according to subgrid section of SIMFLEX module
! ind_tback - time index of srs array calculated from the last index of backward run (i.e. from start time of minimization simulation)
! Note: last time indices of different srs array are attribuited to same time=start time of minimization problem
! n_dur - number of time indices to represent time duration 
      subroutine eval_Jtime(icell,ind_tback,n_dur,Jcur)
      use SIMFLEX,only:obs_val1,AllSRS,Nobs,cmod
      implicit none
       integer icell,ind_tback,n_dur !cell index,time index,number of time levels
!Output
      real JCur      !resulting cor. coef.
      
      integer nt,i,k,ind1
      
      if(.not.allocated(cmod))then
        allocate(cmod(Nobs))
        cmod=0
      elseif(size(cmod,1).eq.Nobs)then
        cmod=0
      else
        write(6,*)'Error from eval_Jtime:allocated array cmod'
        write(6,*)'has dimension size(cmod)=',size(cmod,1)
        write(6,*)'that doesnt coincide with the number of observations'
        write(6,*)'Nobs=',Nobs
        stop
      endif

      do i=1,Nobs
         nt=AllSRS(i)%nt
         
         if(ind_tback.gt.nt)cycle ! respective observation ended earlier than start time of current release
         
         ind1=max(nt-ind_tback-n_dur,1) ! if end of release later than end of obs than the rest are zeros
         do k=ind1,nt-ind_tback+1
            cmod(i)=cmod(i)+AllSRS(i)%srsred(k,1,icell);
         enddo
      enddo

      if(maxval(cmod).gt.0)then
         call corcoef(cmod,obs_val1,Nobs,Jcur);
      else
         Jcur=0;
      endif

      end subroutine eval_Jtime
