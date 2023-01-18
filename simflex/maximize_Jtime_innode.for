! %evaluates start time and duration by
! analyzing concentrations time histories and adjoint concentrations
! 

! (!)Time corresponding to time index of srs decrease with increasing index

! ind_ts is index corresponding to start time of release
! n_dur is number of indices corresponding to release duration
! Ind_tsmax is index for maximum start time of release
! Jmax is maximized correlation coefficient
! as described in algorithm (13) by Andronopoulos and Kovalets (2021)
! Atmosphere, https://doi.org/10.3390/atmos12101305
!icell is index of subgrid selected for time minimization

      subroutine eval_Jtime_innode(icell,Jmax,n_dur_sol,indback_ts_sol)
      use SIMFLEX,only:Indback_tsmax,ndur_min,maxtsrcind
                      
      implicit none
      integer icell
      
      integer indback_tscur,i,j,n_dur_cur
      integer n_dur_sol,indback_ts_sol ! local variables - not those from SIMFLEX module!
      
      real Jmax,Jcur
      

      Jmax=0;
      indback_ts_sol=-9999
      n_dur_sol=-9999
      do i=1,Indback_tsmax 
        indback_tscur=i;
       
        do j=indback_tscur+ndur_min-1,maxtsrcind

         n_dur_cur=j-indback_tscur+1;
         
         call eval_Jtime(icell,indback_tscur,n_dur_cur,Jcur)
        
          if(Jcur.gt.Jmax)then
            Jmax=Jcur;
            indback_ts_sol=indback_tscur;
            n_dur_sol=n_dur_cur;
          endif
        
        enddo
    
      enddo
      
      if(n_dur_sol.lt.0.or.indback_ts_sol.lt.0)then
        write(6,*)'Error from eval_Jtime_innode: '
        write(6,*)'when evaluating release start time and duration'
        write(6,*)'all corr. coeffs are <=0 for selected cell number ',
     &             icell
        write(6,*)'This is strange and should not happen!'
        write(6,*)'Evaluation of time parameters is stopped'
        stop
      endif

      return;
      end subroutine eval_Jtime_innode
