! checks that list of available srs-s (obs_id_all) contains all
! obs id-s passed with measurements and stored in obs_id
       subroutine check_init_locobs_id()
       use SIMFLEX,only:id_obs,id_obs_all,Nobs,Nobs_all,locobsid
       implicit none

       integer i,loc

      write(6,*)'Checking if for every observation srs exists'
      write(6,*)' '

       locobsid=0
       do i=1,Nobs
         call findloc1(id_obs_all,Nobs_all,id_obs(i),loc)
         if(loc.eq.0)then
           write(6,*)'Error from check_obs_id: srs file not found for'
           write(6,*)' obs id=',id_obs(i)
           stop
         else
           locobsid(id_obs(i))=loc
         endif
       enddo
       end subroutine check_init_locobs_id
