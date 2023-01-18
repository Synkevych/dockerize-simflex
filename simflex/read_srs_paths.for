      subroutine read_srs_paths(fname,nfname)
      use SIMFLEX,only:Nobs_all,srsfiles,id_obs_all,
     &                srs_ind_all,MAXOBS
      use parse
      implicit none
      integer nfname
      character(nfname) fname
      character(len=1024), dimension(MAXOBS) :: srsfiles_
      integer id_obs_all_(MAXOBS),srs_ind_all_(MAXOBS)
      integer nstr
      
      character(1024) str2
      character(5) str1,str3
      
      integer i,L,Reason

      write(6,*)'Reading paths to flexpart files with srs-s'
      write(6,*)' '
          
      OPEN(1024,FILE=fname(1:nfname))
      
      read(1024,"(A)")line
      L=0
      do i=1,MAXOBS
        read(1024,"(A)",IOSTAT=Reason)line
        if(Reason.eq.0)then
           L=L+1
           str1=getArg(1)
           str2=getArg(2)
           str3=getArg(3)
           read(str1,*)id_obs_all_(i)
           nstr=len_trim(str2)
           srsfiles_(i)=trim(str2)
           str2(1:nstr)=' '
           read(str3,*)srs_ind_all_(i)
        else
           exit;
        endif
        
      enddo
      
      CLOSE(1024)
      Nobs_all=L
      if(Nobs_all.eq.MAXOBS)then
        write(6,*)'Error from read_srs_paths: number of'
        write(6,*)'lines in file ',fname(1:nfname)
        write(6,*)'reached value=',MAXOBS,'while maximum allowable'
        write(6,*)'value is:',MAXOBS-1
        write(6,*)'Please, revise the respective input file'
        write(6,*)'by removing paths to srs files that are not to be'
        write(6,*)'used in source inversion process'
        stop
      endif
     
      
      allocate(srsfiles(Nobs_all))
      allocate(id_obs_all(Nobs_all))  
      allocate(srs_ind_all(Nobs_all))  
      
      srsfiles(1:Nobs_all)=srsfiles_(1:Nobs_all)
      id_obs_all=id_obs_all_(1:Nobs_all)
      srs_ind_all=srs_ind_all_(1:Nobs_all)
         
      
      end subroutine read_srs_paths
