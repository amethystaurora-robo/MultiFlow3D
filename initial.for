!##########################################################################
        subroutine read_control
!##########################################################################
        use vars
        use multidata
        use mpi
        implicit none
        integer mgi,mgj,mgk,pow2,ib,i,j

        open (unit=12, file='control.cin')
!------DOMAIN SIZE AND DISCRETIZATION -------------------------------------    
	  read (12,*) 
        read (12,*) keyword,ubulk
        read (12,*) g_dx,g_dy,g_dz
        read (12,*) dens,Re,Pr,Sc_t,beta
        read (12,*) gx,gy,gz
        read (12,*) conv_sch
        read (12,*) diff_sch
        read (12,*) differencing
        read (12,*) solver
        read (12,*) ngrid_input,mg_itrsch
        read (12,*) maxcy,irestr,iproln
        read (12,*) dt,L_dt,sweeps,safety_factor
        read (12,*) itime_end,LRESTART,reinitmean,n_out
        read (12,*) LTRANSIENT,tsteps_pt
        read (12,*) niter,eps,nswp(1),nswp(2),nswp(3),nswp(4)
	  read (12,*) 
        read (12,*) bc_w
        read (12,*) bc_e
        read (12,*) bc_s
        read (12,*) bc_n
        read (12,*) bc_b
        read (12,*) bc_t
	  read (12,*) L_n,fric
        read (12,*) save_inflow,ITMAX_PI
	  read (12,*) 
        read (12,*) UPROF_SEM			!Pablo 15/12/2015
        read (12,*) TI_SEM 
        read (12,*) ITMAX_SEM
	  read (12,*) 
!        read (12,*) pressureforce
        if (bc_w.eq.5) pressureforce=.TRUE.

        read (12,*) time_averaging,t_start_averaging1,
     & t_start_averaging2,noise
        read (12,*) SGS,sgs_model
        read (12,*) LMR
        read (12,*) LIMB,LENERGY,LROUGH
        read (12,*) LPT,OMP_threads,LSCALAR,LSTRA
        read (12,*) pl_ex	
        read (12,*) Th,Tc
	  read (12,*) 
        read (12,*) Tbc_w
        read (12,*) Tbc_e
        read (12,*) Tbc_s
        read (12,*) Tbc_n
        read (12,*) Tbc_b
        read (12,*) Tbc_t
        read (12,*)
        read (12,*) L_LSM,reinit,ntime_reinit,reldif_LSM,length,accuracy
     & ,cfl_lsm
	  read (12,*) LENDS
	  read (12,*) L_LSMbase,L_LSMinit
	  read (12,*) L_anim_phi,L_anim_grd 
	  read (12,*) densl,densg,nul,nug
        read (12,*) grx,gry,grz
	  read (12,*) slope
	  read (12,*) 
	  read (12,*) n_unstpt
	  	allocate(id_unst(n_unstpt),i_unst(n_unstpt)
     &		  ,j_unst(n_unstpt),k_unst(n_unstpt))
		do i=1,n_unstpt
			read (12,*)id_unst(i),i_unst(i),j_unst(i),k_unst(i)
		enddo

        mul = nul * densl
        mug = nug * densg

        if (.not.LPT) np=0

	if (trim(L_n).eq.'n') fric=fric**0.33

!        if(bc_w.eq.5 .or. bc_e.eq.5 .or.
!     & bc_s.eq.5 .or. bc_n.eq.5 .or.
!     & bc_b.eq.5 .or. bc_t.eq.5) then
!           PERIODIC=.true.
!        else
!           PERIODIC=.false.
!        end if

        do ib=1,nbp
           dom(ib)%bc_west=bc_w
           dom(ib)%bc_east=bc_e
           dom(ib)%bc_south=bc_s
           dom(ib)%bc_north=bc_n
           dom(ib)%bc_bottom=bc_b
           dom(ib)%bc_top=bc_t
           dom(ib)%Tbc_west=Tbc_w
           dom(ib)%Tbc_east=Tbc_e
           dom(ib)%Tbc_south=Tbc_s
           dom(ib)%Tbc_north=Tbc_n
           dom(ib)%Tbc_bottom=Tbc_b
           dom(ib)%Tbc_top=Tbc_t
           dom(ib)%ngrid=ngrid_input
	     if (dom(ib)%bc_west.eq.7) read_inflow=.true.
        end do

!        if(solver.eq.2 .and. LMR.eq.2) then
!           print*,'error: wrong solver selection for LMR',
!     &' new ghost cell approach!!, STOP'
!           stop
!        end if

        if(differencing.eq.3 .and. pl_ex.ne.2) then
           pl_ex=2
           print*,'error: you select WENO but do not assign',
     &'  correct number of ghost planes,now it is corrected to 2'
        end if

        if(SGS .and. sgs_model.eq.3 .and. pl_ex.ne.2) then
           pl_ex=2
           print*,'error: you select 1-EQN model but do not assign',
     &'  correct number of ghost planes,now it is corrected to 2'
        end if

	  if (L_LSM .and. solver.eq.1) then
	   if (myrank.eq.0) then
          print*,'Error: SIP solver not presently compatible with LSM'
	   endif
	   stop
	  endif

	  if (L_LSM .and. differencing.ne.3) then
	   if (myrank.eq.0) then
          print*,'Error: WENO differencing must be used with LSM'
	   endif
	   stop
	  endif

	  if (L_LSMinit .and. (L_anim_phi .or. L_anim_grd)) then
	   if (myrank.eq.0) then
          print*,'Error: not possible to output animation files',
     &'  for LSM_init run!'
	   endif
	   stop
	  endif

	  if (L_LSMbase .and. L_LSMinit) then
	   if (myrank.eq.0) then
          print*,'Error: L_LSMbase and L_LSMinit cannot both be true!'
	   endif
	   stop
	  endif

	  if (L_LSMbase .and. L_LSM) then
	   if (myrank.eq.0) then
          print*,'Error: L_LSMbase and L_LSM cannot both be true!'
	   endif
	   stop
	  endif

	  if (L_LSMinit .and. (.not.L_LSM)) then
	   if (myrank.eq.0) then
          print*,'Error: L_LSMinit cannot be true if L_LSM is false!'
	   endif
	   stop
	  endif

	  if (L_anim_phi .and. (.not.L_LSM)) then
	   if (myrank.eq.0) then
          print*,'Error: L_anim_phi cannot be true if L_LSM is false!'
	   endif
	   stop
	  endif

        end 
!##########################################################################
        subroutine initial
!##########################################################################
        use vars
        use mpi
        use multidata
        implicit none
        integer :: i,ib,tti,ttj,ttk
        integer :: glevel,gl,mgc_i,mgc_j,mgc_k,is,ie,js,je,ks,ke
        double precision    :: ndx,ndy,ndz,nwxend,nwyend,nwzend

        do ib=1,nbp
           tti=dom(ib)%ttc_i; ttj=dom(ib)%ttc_j
           ttk=dom(ib)%ttc_k

           do i=1,26
              dom(ib)%tg(i)=i*10**5+dom_id(ib)
           end do

           allocate(dom(ib)%x(tti),dom(ib)%y(ttj),dom(ib)%z(ttk))
           allocate(dom(ib)%xc(tti),dom(ib)%yc(ttj),dom(ib)%zc(ttk))

           allocate(dom(ib)%u(tti,ttj,ttk))
           allocate(dom(ib)%v(tti,ttj,ttk))
           allocate(dom(ib)%w(tti,ttj,ttk))
           allocate(dom(ib)%p(tti,ttj,ttk))
           allocate(dom(ib)%pp(tti,ttj,ttk))
           allocate(dom(ib)%sup(tti,ttj,ttk))
           allocate(dom(ib)%ustar(tti,ttj,ttk))
           allocate(dom(ib)%vstar(tti,ttj,ttk))
           allocate(dom(ib)%wstar(tti,ttj,ttk))

           allocate(dom(ib)%uo(tti,ttj,ttk),dom(ib)%uoo(tti,ttj,ttk))
           allocate(dom(ib)%vo(tti,ttj,ttk),dom(ib)%voo(tti,ttj,ttk))  
           allocate(dom(ib)%wo(tti,ttj,ttk),dom(ib)%woo(tti,ttj,ttk))

           allocate(dom(ib)%ap(tti,ttj,ttk),dom(ib)%su(tti,ttj,ttk))
           allocate(dom(ib)%ae(tti,ttj,ttk),dom(ib)%aw(tti,ttj,ttk))
           allocate(dom(ib)%an(tti,ttj,ttk),dom(ib)%as(tti,ttj,ttk))
           allocate(dom(ib)%at(tti,ttj,ttk),dom(ib)%ab(tti,ttj,ttk))

           allocate(dom(ib)%um(tti,ttj,ttk),dom(ib)%vm(tti,ttj,ttk))
           allocate(dom(ib)%wm(tti,ttj,ttk),dom(ib)%pm(tti,ttj,ttk))
           allocate(dom(ib)%uum(tti,ttj,ttk),dom(ib)%vvm(tti,ttj,ttk))
           allocate(dom(ib)%wwm(tti,ttj,ttk),dom(ib)%uvm(tti,ttj,ttk))
           allocate(dom(ib)%uwm(tti,ttj,ttk),dom(ib)%vwm(tti,ttj,ttk))
           allocate(dom(ib)%ppm(tti,ttj,ttk))

           allocate(dom(ib)%ntav1(tti,ttj,ttk))
           allocate(dom(ib)%ntav2(tti,ttj,ttk))
           allocate(dom(ib)%facp1(tti,ttj,ttk))
           allocate(dom(ib)%facp2(tti,ttj,ttk))
           allocate(dom(ib)%facm1(tti,ttj,ttk))
           allocate(dom(ib)%facm2(tti,ttj,ttk))

	     dom(ib)%ntav1=0
    	     dom(ib)%ntav2=0
    	     dom(ib)%facp1=0
    	     dom(ib)%facp2=0
    	     dom(ib)%facm1=1
    	     dom(ib)%facm2=1
           ntav1_count = 0 !Aleks 04/24
           ntav2_count = 0 !Aleks 04/24

           allocate (dom(ib)%vis(tti,ttj,ttk))
           allocate(dom(ib)%ksgs(tti,ttj,ttk))
           allocate(dom(ib)%ksgso(tti,ttj,ttk))
           allocate(dom(ib)%eps(tti,ttj,ttk))
           allocate(dom(ib)%epso(tti,ttj,ttk))
           allocate (dom(ib)%stfcinf(6,pl,ngg))
           allocate(dom(ib)%T(tti,ttj,ttk),dom(ib)%To(tti,ttj,ttk))
           allocate(dom(ib)%Tm(tti,ttj,ttk),dom(ib)%Ttm(tti,ttj,ttk))

           	allocate(dom(ib)%S(tti,ttj,ttk),dom(ib)%Sm(tti,ttj,ttk))
            allocate (dom(ib)%dens_mg(dom(ib)%tot))

	     if (LSCALAR) then
           	allocate(dom(ib)%So(tti,ttj,ttk),dom(ib)%Stm(tti,ttj,ttk))
	   	allocate(dom(ib)%sfactor(tti,ttj,ttk))
	     endif

           if (L_LSM)! .or. L_LSMbase) 
     & allocate(dom(ib)%dens(tti,ttj,ttk),
     & dom(ib)%mu(tti,ttj,ttk),dom(ib)%ijkp_lsm(0:dom(ib)%ngrid))

           if (LENERGY.or.LSCALAR)
     & allocate(dom(ib)%dens(tti,ttj,ttk),
     & dom(ib)%mu(tti,ttj,ttk),dom(ib)%ijkp_lsm(0:dom(ib)%ngrid))
        
           if (L_LSM) then! .or. L_LSMbase) then
             dom(ib)%ijkp_lsm = 0
             dom(ib)%ijkp_lsm(1)=(dom(ib)%ttc_i-2*pl)*
     & (dom(ib)%ttc_j-2*pl)*(dom(ib)%ttc_k-2*pl) 
             do glevel=2,dom(ib)%ngrid
               mgc_i=(dom(ib)%iep-dom(ib)%isp+1)/2**(glevel-1)+2
               mgc_j=(dom(ib)%jep-dom(ib)%jsp+1)/2**(glevel-1)+2
               mgc_k=(dom(ib)%kep-dom(ib)%ksp+1)/2**(glevel-1)+2
               dom(ib)%ijkp_lsm(glevel)=dom(ib)%ijkp_lsm(glevel-1)+
     & (mgc_i-2)*(mgc_j-2)*(mgc_k-2)
             end do
             dom(ib)%tot=dom(ib)%ijkp_lsm(dom(ib)%ngrid)
           end if

           if (differencing.eq.3) allocate(dom(ib)%d1(tti,ttj,ttk),
     & dom(ib)%dphi_dxplus(tti,ttj,ttk),
     & dom(ib)%dphi_dxminus(tti,ttj,ttk),
     & dom(ib)%dphi_dyplus(tti,ttj,ttk),
     & dom(ib)%dphi_dyminus(tti,ttj,ttk),
     & dom(ib)%dphi_dzplus(tti,ttj,ttk),
     & dom(ib)%dphi_dzminus(tti,ttj,ttk))

              allocate (dom(ib)%tauwe(ttj,ttk))
              allocate (dom(ib)%tauww(ttj,ttk))
              allocate (dom(ib)%tauwn(tti,ttk))
              allocate (dom(ib)%tauws(tti,ttk))
              allocate (dom(ib)%tauwt(tti,ttj))
              allocate (dom(ib)%tauwb(tti,ttj))
              allocate (dom(ib)%tauwe2(ttj,ttk))
              allocate (dom(ib)%tauww2(ttj,ttk))
              allocate (dom(ib)%tauwn2(tti,ttk))
              allocate (dom(ib)%tauws2(tti,ttk))
              allocate (dom(ib)%tauwt2(tti,ttj))
              allocate (dom(ib)%tauwb2(tti,ttj))

           if(solver.eq.2) then
              allocate (dom(ib)%faz(ngrd_gl))
           end if

           allocate (dom(ib)%sendb_m1(ngg)) 
           allocate (dom(ib)%sendb_p1(ngg))
           allocate (dom(ib)%recvb_m1(ngg))
           allocate (dom(ib)%recvb_p1(ngg))
           allocate (dom(ib)%sendb_m2(ngg)) 
           allocate (dom(ib)%sendb_p2(ngg))
           allocate (dom(ib)%recvb_m2(ngg))
           allocate (dom(ib)%recvb_p2(ngg))
           allocate (dom(ib)%sendb_m3(ngg)) 
           allocate (dom(ib)%sendb_p3(ngg))
           allocate (dom(ib)%recvb_m3(ngg))
           allocate (dom(ib)%recvb_p3(ngg))

           allocate (dom(ib)%sc1m(ngc),dom(ib)%sc1p(ngc))
           allocate (dom(ib)%rc1m(ngc),dom(ib)%rc1p(ngc))
           allocate (dom(ib)%sc2m(ngc),dom(ib)%sc2p(ngc))
           allocate (dom(ib)%rc2m(ngc),dom(ib)%rc2p(ngc))
           allocate (dom(ib)%sc3m(ngc),dom(ib)%sc3p(ngc))
           allocate (dom(ib)%rc3m(ngc),dom(ib)%rc3p(ngc))
           allocate (dom(ib)%sc4m(ngc),dom(ib)%sc4p(ngc))
           allocate (dom(ib)%rc4m(ngc),dom(ib)%rc4p(ngc))

           allocate (dom(ib)%se1m(nge),dom(ib)%se1p(nge))
           allocate (dom(ib)%re1m(nge),dom(ib)%re1p(nge))
           allocate (dom(ib)%se2m(nge),dom(ib)%se2p(nge))
           allocate (dom(ib)%re2m(nge),dom(ib)%re2p(nge))
           allocate (dom(ib)%se3m(nge),dom(ib)%se3p(nge))
           allocate (dom(ib)%re3m(nge),dom(ib)%re3p(nge))
           allocate (dom(ib)%se4m(nge),dom(ib)%se4p(nge))
           allocate (dom(ib)%re4m(nge),dom(ib)%re4p(nge))
           allocate (dom(ib)%se5m(nge),dom(ib)%se5p(nge))
           allocate (dom(ib)%re5m(nge),dom(ib)%re5p(nge))
           allocate (dom(ib)%se6m(nge),dom(ib)%se6p(nge))
           allocate (dom(ib)%re6m(nge),dom(ib)%re6p(nge))


           dom(ib)%x(1)=dom(ib)%xsl +(-pl+1)*dom(ib)%dx
           dom(ib)%y(1)=dom(ib)%ysl +(-pl+1)*dom(ib)%dy
           dom(ib)%z(1)=dom(ib)%zsl +(-pl+1)*dom(ib)%dz
           dom(ib)%xc(1)=dom(ib)%x(1)-0.5*dom(ib)%dx
           dom(ib)%yc(1)=dom(ib)%y(1)-0.5*dom(ib)%dy
           dom(ib)%zc(1)=dom(ib)%z(1)-0.5*dom(ib)%dz

           do i=2,dom(ib)%ttc_i
              dom(ib)%x(i)=dom(ib)%x(i-1)+dom(ib)%dx
           end do
           do i=2,dom(ib)%ttc_j
              dom(ib)%y(i)=dom(ib)%y(i-1)+dom(ib)%dy
           end do
           do i=2,dom(ib)%ttc_k
              dom(ib)%z(i)=dom(ib)%z(i-1)+dom(ib)%dz
           end do

           do i=1,dom(ib)%ttc_i
              dom(ib)%xc(i)=dom(ib)%x(i)-0.5*dom(ib)%dx
           end do
           do i=1,dom(ib)%ttc_j
              dom(ib)%yc(i)=dom(ib)%y(i)-0.5*dom(ib)%dy
           end do
           do i=1,dom(ib)%ttc_k
              dom(ib)%zc(i)=dom(ib)%z(i)-0.5*dom(ib)%dz
           end do

           if (dom(ib)%inext.ge.0) then
              if(abs(dom(ib)%x(dom(ib)%iep)-dom(ib)%xel).gt.1e-5) then
                 print*,'mycpu#:',myrank,' error-11'
                 stop
              end if
           end if

           if (dom(ib)%jnext.ge.0) then
              if(abs(dom(ib)%y(dom(ib)%jep)-dom(ib)%yel).gt.1e-5) then
                 print*,'mycpu#:',myrank,' error-12'
                 stop
              end if
           end if

           if (dom(ib)%knext.ge.0) then
              if(abs(dom(ib)%z(dom(ib)%kep)-dom(ib)%zel).gt.1e-5) then
                 print*,'mycpu#:',myrank,' error-13'
                 stop
              end if
           end if

           if(solver.eq.2 .and. ngrd_gl.ge.2) then

              is=dom(ib)%isp; ie=dom(ib)%iep
              js=dom(ib)%jsp; je=dom(ib)%jep
              ks=dom(ib)%ksp; ke=dom(ib)%kep

              do glevel=2,ngrd_gl
                 if(glevel.gt.dom(ib)%ngrid) then
                    gl=dom(ib)%ngrid
                 else
                    gl=glevel
                 end if
                 mgc_i=(ie-is+1)/2**(gl-1)+2
                 mgc_j=(je-js+1)/2**(gl-1)+2
                 mgc_k=(ke-ks+1)/2**(gl-1)+2

                 ndx=dom(ib)%dx*2**(gl-1)
                 ndy=dom(ib)%dy*2**(gl-1)
                 ndz=dom(ib)%dz*2**(gl-1)

                 nwxend=dom(ib)%x(dom(ib)%isp-1)+ndx*(mgc_i-2)
                 nwyend=dom(ib)%y(dom(ib)%jsp-1)+ndy*(mgc_j-2)
                 nwzend=dom(ib)%z(dom(ib)%ksp-1)+ndz*(mgc_k-2)

                 if((abs(dom(ib)%x(dom(ib)%iep)-nwxend).gt.1e-8)
     &  .or.(abs(dom(ib)%y(dom(ib)%jep)-nwyend).gt.1e-8)
     &  .or.(abs(dom(ib)%z(dom(ib)%kep)-nwzend).gt.1e-8)) then
                    print*,'==ERROR==> in multigrid: max ngrid value'
                    stop
                 end if
              end do 
           end if

        end do
        

        end subroutine initial
!##########################################################################
        subroutine iniflux
!##########################################################################
        use vars
        use multidata
        use mpi
        implicit none
        integer i,j,k,ib,ispr,iepr,jspr,jepr,kspr,kepr
        double precision buffer_flomas

        MPI_FLT = MPI_DOUBLE_PRECISION

        flomas=0.0

        do ib=1,nbp
           ispr=pl+1; iepr=dom(ib)%ttc_i-pl
           jspr=pl+1; jepr=dom(ib)%ttc_j-pl
           kspr=pl+1; kepr=dom(ib)%ttc_k-pl

           if(dom(ib)%iprev.lt.0) then
		if (dom(ib)%bc_west.lt.61 .and. dom(ib)%bc_west.ne.4) then
              do j=jspr,jepr 
                 do k=kspr,kepr
	             if (L_LSM) then
			   if (dom(ib)%phi(dom(ib)%isu-1,j,k) .ge. 0.0) then
                       flomas=flomas+dom(ib)%u(dom(ib)%isu-1,j,k)*
     &  dom(ib)%dy*dom(ib)%dz
			   end if
			 else
                     flomas=flomas+dom(ib)%u(dom(ib)%isu-1,j,k)*
     &  dom(ib)%dy*dom(ib)%dz
			 end if
                 end do
              end do
		endif
           end if

           if(dom(ib)%jprev.lt.0) then
		if (dom(ib)%bc_south.lt.61 .and. dom(ib)%bc_south.ne.4) then
              do k=kspr,kepr
                 do i=ispr,iepr
	             if (L_LSM) then
			   if (dom(ib)%phi(i,dom(ib)%jsv-1,k) .ge. 0.0) then
                       flomas=flomas+dom(ib)%v(i,dom(ib)%jsv-1,k)*
     &  dom(ib)%dx*dom(ib)%dz
			   end if
			 else
                     flomas=flomas+dom(ib)%v(i,dom(ib)%jsv-1,k)*
     &  dom(ib)%dx*dom(ib)%dz
			 end if
                 end do
              end do
		endif
           end if

        if(dom(ib)%kprev.lt.0) then
	     if (dom(ib)%bc_bottom.lt.61.and.dom(ib)%bc_bottom.ne.4) then         
              do j=jspr,jepr
                 do i=ispr,iepr
	             if (L_LSM) then
			   if (dom(ib)%phi(i,j,dom(ib)%ksw-1) .ge. 0.0) then
                       flomas=flomas+dom(ib)%w(i,j,dom(ib)%ksw-1)*
     &  dom(ib)%dx*dom(ib)%dy
			   end if
			 else
                     flomas=flomas+dom(ib)%w(i,j,dom(ib)%ksw-1)*
     &  dom(ib)%dx*dom(ib)%dy
			 end if
                 end do
              end do
		endif
           end if
        end do

        buffer_flomas = flomas
        call MPI_ALLREDUCE(buffer_flomas,flomas,1,MPI_FLT,MPI_SUM,
     & MPI_COMM_WORLD,ierr)
         
        return
        end 
!##########################################################################
        subroutine correctoutflux
!##########################################################################
        use vars
        use multidata
        use mpi
        implicit none
        integer i,j,k,ib,ispr,iepr,jspr,jepr,kspr,kepr
        double precision fmout,fct,buffer_fmout

        MPI_FLT = MPI_DOUBLE_PRECISION

        fmout=0.0

        do ib=1,nbp
           ispr=pl+1; iepr=dom(ib)%ttc_i-pl
           jspr=pl+1; jepr=dom(ib)%ttc_j-pl
           kspr=pl+1; kepr=dom(ib)%ttc_k-pl

           if(dom(ib)%inext.lt.0) then
		if (dom(ib)%bc_east.lt.61 .and. dom(ib)%bc_east.ne.4) then    
              do j=jspr,jepr 
                 do k=kspr,kepr
	             if (L_LSM) then
			   if (dom(ib)%phi(dom(ib)%ieu+1,j,k) .ge. 0.0) then  
                       fmout=fmout+dom(ib)%u(dom(ib)%ieu+1,j,k)*
     &  dom(ib)%dy*dom(ib)%dz
			   end if
			 else
                     fmout=fmout+dom(ib)%u(dom(ib)%ieu+1,j,k)*
     &  dom(ib)%dy*dom(ib)%dz
			 end if
                 end do
              end do    
		endif
           end if

           if(dom(ib)%jnext.lt.0) then
		if (dom(ib)%bc_north.lt.61 .and. dom(ib)%bc_north.ne.4) then    
              do k=kspr,kepr
                 do i=ispr,iepr
	             if (L_LSM) then
			   if (dom(ib)%phi(i,dom(ib)%jev+1,k) .ge. 0.0) then
                       fmout=fmout+dom(ib)%v(i,dom(ib)%jev+1,k)*
     &  dom(ib)%dx*dom(ib)%dz
			   end if
			 else
                     fmout=fmout+dom(ib)%v(i,dom(ib)%jev+1,k)*
     &  dom(ib)%dx*dom(ib)%dz
			 end if
                 end do
              end do   
		endif 
           end if

           if(dom(ib)%knext.lt.0) then
		if (dom(ib)%bc_top.lt.61 .and. dom(ib)%bc_top.ne.4) then    
              do j=jspr,jepr
                 do i=ispr,iepr
	             if (L_LSM) then
			   if (dom(ib)%phi(i,j,dom(ib)%kew+1) .ge. 0.0) then
                       fmout=fmout+dom(ib)%w(i,j,dom(ib)%kew+1)*
     &  dom(ib)%dx*dom(ib)%dy
			   end if
			 else
                     fmout=fmout+dom(ib)%w(i,j,dom(ib)%kew+1)*
     &  dom(ib)%dx*dom(ib)%dy
			 end if
                 end do
              end do   
		endif 
           end if
        end do

        buffer_fmout = fmout
        call MPI_ALLREDUCE(buffer_fmout,fmout,1,MPI_FLT,MPI_SUM,
     &MPI_COMM_WORLD,ierr)

        fct=flomas/(fmout+1.E-30)

        Mdef=flomas-fmout

        do ib=1,nbp
           if(dom(ib)%inext.lt.0) then
		if (dom(ib)%bc_east.lt.61 .and. dom(ib)%bc_east.ne.4) then    
              do j=dom(ib)%jsu,dom(ib)%jeu 
                 do k=dom(ib)%ksu,dom(ib)%keu  
                    dom(ib)%u(dom(ib)%ieu+1,j,k)=
     & dom(ib)%u(dom(ib)%ieu+1,j,k)*fct
                 end do
              end do

              do j=dom(ib)%jsv,dom(ib)%jev 
                 do k=dom(ib)%ksv,dom(ib)%kev  
                    dom(ib)%v(dom(ib)%iev+1,j,k)=
     & dom(ib)%v(dom(ib)%iev+1,j,k)*fct
                 end do
              end do

              do j=dom(ib)%jsw,dom(ib)%jew 
                 do k=dom(ib)%ksw,dom(ib)%kew  
                    dom(ib)%w(dom(ib)%iew+1,j,k)=
     & dom(ib)%w(dom(ib)%iew+1,j,k)*fct
                 end do
              end do
		endif
           end if

           if(dom(ib)%jnext.lt.0) then
		if (dom(ib)%bc_north.lt.61 .and. dom(ib)%bc_north.ne.4) then    
              do i=dom(ib)%isu,dom(ib)%ieu 
                 do k=dom(ib)%ksu,dom(ib)%keu  
                    dom(ib)%u(i,dom(ib)%jeu+1,k)=
     & dom(ib)%u(i,dom(ib)%jeu+1,k)*fct
                 end do
              end do

              do i=dom(ib)%isv,dom(ib)%iev 
                 do k=dom(ib)%ksv,dom(ib)%kev  
                    dom(ib)%v(i,dom(ib)%jev+1,k)=
     & dom(ib)%v(i,dom(ib)%jev+1,k)*fct
                 end do
              end do

              do i=dom(ib)%isw,dom(ib)%iew 
                 do k=dom(ib)%ksw,dom(ib)%kew  
                    dom(ib)%w(i,dom(ib)%jew+1,k)=
     & dom(ib)%w(i,dom(ib)%jew+1,k)*fct
                 end do
              end do
		endif
           end if

           if(dom(ib)%knext.lt.0) then
		if (dom(ib)%bc_top.lt.61 .and. dom(ib)%bc_top.ne.4) then    
              do i=dom(ib)%isu,dom(ib)%ieu 
                 do j=dom(ib)%jsu,dom(ib)%jeu  
                    dom(ib)%u(i,j,dom(ib)%keu+1)=
     & dom(ib)%u(i,j,dom(ib)%keu+1)*fct
                 end do
              end do

              do i=dom(ib)%isv,dom(ib)%iev 
                 do j=dom(ib)%jsv,dom(ib)%jev  
                    dom(ib)%v(i,j,dom(ib)%kev+1)=
     & dom(ib)%v(i,j,dom(ib)%kev+1)*fct
                 end do
              end do

              do i=dom(ib)%isw,dom(ib)%iew 
                 do j=dom(ib)%jsw,dom(ib)%jew  
                    dom(ib)%w(i,j,dom(ib)%kew+1)=
     & dom(ib)%w(i,j,dom(ib)%kew+1)*fct
                 end do
              end do
		endif
           end if
        end do

        return
        end 
!##########################################################################
        subroutine initflowfield
!##########################################################################
        use vars
        use mpi
        use multidata
        implicit none
        integer :: i,j,k,ib,tti,ttj,ttk,pll
        integer :: sn,sn2
        integer :: inind,jnind,knind
        double precision dum,ubw,ube,ubs,ubn,ubt,ubb,vb,wb,lz
        double precision, dimension(21) :: dm
        character*8   :: chb1
        character*25  :: gf
        character*100 :: dummyline

        do ib=1,nbp

           tti=dom(ib)%ttc_i
           ttj=dom(ib)%ttc_j
           ttk=dom(ib)%ttc_k

           if (LRESTART) then

              qzero=ubulk !brunho2014
              open (unit=700, file='final_ctime.dat')
              read (700,'(i8,3F15.6)') ntime,ctime,forcn,qstpn,count
     &          ,ntav1_count,ntav2_count
              close (700)
              if (.not.reinitmean) then !Aleks 04/24
              dom(ib)%ntav1=ntav1_count
              dom(ib)%ntav2=ntav2_count
              ntav_restart=ntav2_count
              endif

              write(chb1,'(i8)') dom_id(ib)
              sn=len(trim(adjustl(chb1)))
              chb1=repeat('0',(4-sn))//trim(adjustl(chb1))

!===============================================================
              gf='tecbin'//trim(adjustl(chb1))//'.bin'
              open (unit=700, file=gf, form='unformatted',status='old')

              read (700) tti,ttj,ttk
              read (700) pll
              read (700) inind,jnind,knind

              if(pll.ne.pl .and. myrank.eq.0) then
        print*,'&*&* different number of overlapping layers!!',pl,pll
        write(numfile,*) '&*&* different number of overlapping layers!!'
        stop
              end if

              do k=1,ttk
                 do j=1,ttj
                    do i=1,tti

                       read (700) dm(1),dm(2),dm(3),dm(4),dm(5),dm(6),
     & dm(7),dm(8),dm(9),dm(10),dm(11),dm(12),dm(13),dm(14),dm(15),
     & dm(16),dm(17),dm(18),dm(19)!,dm(20),dm(21),dm(22),dm(23),
   !   & dm(24)!,dm(25)

                       dom(ib)%p  (i,j,k)=dm(4)
                       dom(ib)%pm (i,j,k)=dm(5)
                       dom(ib)%ppm(i,j,k)=dm(6)
                       dom(ib)%vis(i,j,k)=dm(7)
                		 dom(ib)%u  (i,j,k)=dm(8)
                		 dom(ib)%um (i,j,k)=dm(9)
                		 dom(ib)%uum(i,j,k)=dm(10)
                		 dom(ib)%v  (i,j,k)=dm(11)
                		 dom(ib)%vm (i,j,k)=dm(12)
                		 dom(ib)%vvm(i,j,k)=dm(13)
                		 dom(ib)%w  (i,j,k)=dm(14)
                		 dom(ib)%wm (i,j,k)=dm(15)
                		 dom(ib)%wwm(i,j,k)=dm(16)
                		 dom(ib)%uvm(i,j,k)=dm(17)
                		 dom(ib)%uwm(i,j,k)=dm(18)
                		 dom(ib)%vwm(i,j,k)=dm(19)
!		  	     endif
!                      dom(ib)%S(i,j,k)=dm(20)
!                      dom(ib)%dens(i,j,k)=dm(21)
!              	     dom(ib)%Sm(i,j,k) = dm(21)
                  !      dom(ib)%ksgs(i,j,k)=dm(20)
              	   !   dom(ib)%eps(i,j,k) = dm(21)
                  !      dom(ib)%T(i,j,k)=dm(22)
                  !      dom(ib)%Tm(i,j,k)=dm(23)
                  !      dom(ib)%Ttm(i,j,k)=dm(24)

                    end do
                 end do
              end do
              close (700)
!===============================================================

              if (reinitmean) then
                 dom(ib)%um   = 0.0; dom(ib)%vm   = 0.0
                 dom(ib)%wm   = 0.0; dom(ib)%pm   = 0.0
                 dom(ib)%uum  = 0.0; dom(ib)%vvm  = 0.0
                 dom(ib)%wwm  = 0.0; dom(ib)%uvm  = 0.0
                 dom(ib)%uwm  = 0.0; dom(ib)%vwm  = 0.0
                 dom(ib)%ppm  = 0.0
                 dom(ib)%Tm   = 0.0; dom(ib)%Ttm  = 0.0
                 ctime=0.0
                 ntime=0
		     if (L_LSM) dom(ib)%phim  = 0.0
              end if
           else !no restart

              qzero=ubulk 								!brunho2014
              qstpn=qzero
              forcn=2.0/(Re*qzero)
              ctime=0.0
              ntime=0

	        if (L_LSMbase) then
                do k=2,ttk
                  do j=1,ttj
                    do i=1,tti
			    if (dom(ib)%z(k-1).le.length) then
	                  dom(ib)%u(i,j,k)=Ubulk  
	                  dom(ib)%uo(i,j,k)=Ubulk 
				dom(ib)%uoo(i,j,k)=Ubulk
			    else
				dom(ib)%u(i,j,k)=0.0
                        dom(ib)%uo(i,j,k)=0.0
			      dom(ib)%uoo(i,j,k)=0.0
			    end if
			  end do
		      end do
		    end do
		  else if (L_LSM) then
                do k=2,ttk
                  do j=1,ttj
                    do i=1,tti
			    if (dom(ib)%phi(i,j,k).ge.0.0) then
	                  dom(ib)%u(i,j,k)=Ubulk  
	                  dom(ib)%uo(i,j,k)=Ubulk 
				dom(ib)%uoo(i,j,k)=Ubulk
			    else
				dom(ib)%u(i,j,k)=0.0
                        dom(ib)%uo(i,j,k)=0.0
			      dom(ib)%uoo(i,j,k)=0.0
			    end if
			  end do
		      end do
		    end do
		  else
		    dom(ib)%u=Ubulk
                dom(ib)%uo=Ubulk 
		    dom(ib)%uoo=Ubulk	
		  end if

	   	  lz=zen-zst
	        if (L_LSM) lz=length
	        if (L_LSMbase) lz=length

!======================STRATIFICATION CONDITIONS========================
!                do k=1,ttk
!                  do j=1,ttj
!                    do i=1,tti
!		if (dom(ib)%z(k).gt.0.66) then
!              dom(ib)%T(i,j,k)=5.;  dom(ib)%To(i,j,k)=5.
!		elseif (dom(ib)%z(k).le.0.66.and.dom(ib)%z(k).gt.0.33) then
!              dom(ib)%T(i,j,k)=0.;  dom(ib)%To(i,j,k)=0.
!		elseif (dom(ib)%z(k).le.0.33) then
!              dom(ib)%T(i,j,k)=-5.;  dom(ib)%To(i,j,k)=-5.
!		endif
!			  end do
!		      end do
!		    end do
!=======================================================================
           if (.not.LRESTART) then 
            if (LENERGY.or.LSTRA) then
                   do k=dom(ib)%ksp-1,dom(ib)%kep+1 !1,ttk !
                      do j=dom(ib)%jsp-1,dom(ib)%jep+1  !1,ttj !
                        do i=dom(ib)%isp-1,dom(ib)%iep+1  !1,tti !
 !		temp_sum = 0.5*(dom(ib)%z(k)+dom(ib)%z(k+1))
               dom(ib)%p(i,j,k)= abs(gz)*(zen-dom(ib)%z(k))
 !        & -(zen-dom(ib)%z(k)))
 
              end do
            end do
              end do
           else
          dom(ib)%p=0.0 		
           endif 
           endif
 

                 dom(ib)%v=0.0; dom(ib)%w=0.0
            !   dom(ib)%p=0.0
              dom(ib)%vo=0.0; dom(ib)%voo=0.0
              dom(ib)%wo=0.0; dom(ib)%woo=0.0
      if (LENERGY) then
              dom(ib)%T=293.0000001d0;  dom(ib)%To=293.0000001d0
              dom(ib)%Tm=0.0; dom(ib)%Ttm=0.0
      endif        
      if (LSCALAR) then
              dom(ib)%S=0.0;  dom(ib)%So=0.0
              dom(ib)%Sm=0.0; dom(ib)%Stm=0.0
      endif

              dom(ib)%vis  = 1.0/Re

              dom(ib)%um   = 0.0; dom(ib)%vm   = 0.0
              dom(ib)%wm   = 0.0; dom(ib)%pm   = 0.0
              dom(ib)%uum  = 0.0; dom(ib)%vvm  = 0.0
              dom(ib)%wwm  = 0.0; dom(ib)%uvm  = 0.0
              dom(ib)%uwm  = 0.0; dom(ib)%vwm  = 0.0
              dom(ib)%ppm  = 0.0

       	     dom(ib)%tauww  = 0.0; dom(ib)%tauww2  = 0.0
              dom(ib)%tauwe  = 0.0; dom(ib)%tauwe2  = 0.0
              dom(ib)%tauws  = 0.0; dom(ib)%tauws2  = 0.0
              dom(ib)%tauwn  = 0.0; dom(ib)%tauwn2  = 0.0
              dom(ib)%tauwb  = 0.0; dom(ib)%tauwb2  = 0.0
              dom(ib)%tauwt  = 0.0; dom(ib)%tauwt2  = 0.0
              !dom(ib)%ksgs = 0.0
              !dom(ib)%eps  = 0.0
      if (sgs_model.gt.2) then
              dom(ib)%ksgs = (3.d0/2.d0)*(ubulk*0.1)**2.0
              dom(ib)%eps  = 0.09**0.75*dom(ib)%ksgs**1.5/(0.07*lz)	
       endif

              if (trim(keyword).eq.'channel') then
                if (.not.L_LSM .and. .not.L_LSMbase) then
		       dom(ib)%u=ubulk
		    end if
                   ubw=ubulk; ube=ubulk; ubs=ubulk				!brunho2014
		       ubn=ubulk; ubt=ubulk; ubb=ubulk
                   vb=0.0; wb=0.0
              else if (trim(keyword).eq.'cavity') then
                 dom(ib)%u=0.0
                 ubw=0.0; ube=0.0; ubs=0.0; ubn=2.0; ubt=0.0; ubb=0.0
                 vb=0.0; wb=0.0
		  else if (trim(keyword).eq.'column') then
                 dom(ib)%u=0.0
                 ubw=0.0; ube=0.0; ubs=0.0; ubn=0.0; ubt=0.0; ubb=0.0
                 vb=0.0; wb=0.0
              else
                 write (6,*) ' wrong keyword '
              end if

!..............U=> West and East ...............
              if (dom(ib)%iprev.lt.0) then
                do k=1,ttk
                  do j=1,ttj
	              if (L_LSMbase .or. (L_LSM.and..not.lrestart)) then
		          if (dom(ib)%zc(k).gt.length) then   
                        dom(ib)%u(dom(ib)%isu-1,j,k) = 0.0 
		          end if
	              else
                      dom(ib)%u(dom(ib)%isu-1,j,k) = ubw
 	              end if
                  end do
                end do 
              end if
              if (dom(ib)%inext.lt.0) then
                do k=1,ttk
                  do j=1,ttj
	              if (L_LSMbase .or. (L_LSM.and..not.lrestart)) then
		          if (dom(ib)%zc(k).gt.length) then   
                        dom(ib)%u(dom(ib)%ieu+1,j,k) = 0.0 
		          end if
	              else
                      dom(ib)%u(dom(ib)%ieu+1,j,k) = ube
	              end if 
                  end do
                end do 
              end if
!.............U=> South and North .................
              if (dom(ib)%jprev.lt.0) then
                do k=1,ttk
                  do i=1,tti
	              if (L_LSMbase .or. (L_LSM.and..not.lrestart)) then
		          if (dom(ib)%zc(k).gt.length) then   
                        dom(ib)%u(i,dom(ib)%jsu-1,k) = 0.0 
		          end if
	              else
                      dom(ib)%u(i,dom(ib)%jsu-1,k) = ubs
	              end if
                  end do
                end do 
              end if
              if (dom(ib)%jnext.lt.0) then
                do k=1,ttk
                  do i=1,tti
	              if (L_LSMbase .or. (L_LSM.and..not.lrestart)) then
		          if (dom(ib)%zc(k).gt.length) then  
                        dom(ib)%u(i,dom(ib)%jeu+1,k) = 0.0 
		          end if
	              else
                       dom(ib)%u(i,dom(ib)%jeu+1,k) = ubn
                    end if
                  end do
                end do 
              end if
!.............U=> Bottom and Top .................
              if (dom(ib)%kprev.lt.0) then
                 do j=1,ttj
                    do i=1,tti
                       dom(ib)%u(i,j,dom(ib)%ksu-1) = ubb
                    end do
                 end do 
              end if
              if (dom(ib)%knext.lt.0) then
                do j=1,ttj
                  do i=1,tti
	              if (L_LSMbase.or. (L_LSM.and..not.lrestart)) then 
                      dom(ib)%u(i,j,dom(ib)%keu+1) = 0.0 
	              else
                      dom(ib)%u(i,j,dom(ib)%keu+1) = ubt
	              end if
                  end do
                end do 
              end if
!........... V=> West and East ....................
              if (dom(ib)%iprev.lt.0) then
                 do k=1,ttk
                    do j=1,ttj
                       dom(ib)%v(dom(ib)%isv-1,j,k)    = vb
                    end do
                 end do 
              end if
              if (dom(ib)%inext.lt.0) then
                 do k=1,ttk
                    do j=1,ttj
                       dom(ib)%v(dom(ib)%iev+1,j,k)  = vb
                    end do
                 end do 
              end if
!............V=> South and North ....................
              if (dom(ib)%jprev.lt.0) then
                 do k=1,ttk
                    do i=1,tti
                       dom(ib)%v(i,dom(ib)%jsv-1,k)    = vb
                    end do
                 end do 
              end if
              if (dom(ib)%jnext.lt.0) then
                 do k=1,ttk
                    do i=1,tti
                       dom(ib)%v(i,dom(ib)%jev+1,k)  = vb
                    end do
                 end do 
              end if
!.............V=> Bottom and Top .................
              if (dom(ib)%kprev.lt.0) then
                 do j=1,ttj
                    do i=1,tti
                       dom(ib)%v(i,j,dom(ib)%ksv-1)    = vb
                    end do
                 end do 
              end if
              if (dom(ib)%knext.lt.0) then
                 do j=1,ttj
                    do i=1,tti
                       dom(ib)%v(i,j,dom(ib)%kev+1)  = vb
                    end do
                 end do 
              end if
!........... W=> West and East ....................
              if (dom(ib)%iprev.lt.0) then
                 do k=1,ttk
                    do j=1,ttj
                       dom(ib)%w(dom(ib)%isw-1,j,k)    = wb
                    end do
                 end do 
              end if
              if (dom(ib)%inext.lt.0) then
                 do k=1,ttk
                    do j=1,ttj
                       dom(ib)%w(dom(ib)%iew+1,j,k)  = wb
                    end do
                 end do 
              end if
!............W=> South and North ....................
              if (dom(ib)%jprev.lt.0) then
                 do k=1,ttk
                    do i=1,tti
                       dom(ib)%w(i,dom(ib)%jsw-1,k)    = wb
                    end do
                 end do 
              end if
              if (dom(ib)%jnext.lt.0) then
                 do k=1,ttk
                    do i=1,tti
                       dom(ib)%w(i,dom(ib)%jew+1,k)  = wb
                    end do
                 end do 
              end if
!.............W=> Bottom and Top .................
              if (dom(ib)%kprev.lt.0) then
                 do j=1,ttj
                    do i=1,tti
                       dom(ib)%w(i,j,dom(ib)%ksw-1)    = wb
                    end do
                 end do 
              end if
              if (dom(ib)%knext.lt.0) then
                 do j=1,ttj
                    do i=1,tti
                       dom(ib)%w(i,j,dom(ib)%kew+1)  = wb
                    end do
                 end do 
              end if


!.######### U=> When power law inlet condition, 7 Dic 2015 .##########
!          IF (dom(ib)%bc_west.eq.12 .or. UPROF_SEM.eq.12) THEN		
          IF (dom(ib)%bc_west.eq.12) THEN				
           do i = dom(ib)%isu-1,dom(ib)%ieu+1 
		do j = dom(ib)%jsu-1,dom(ib)%jeu+1
		 do k = dom(ib)%ksu-1,dom(ib)%keu+1
	  if (dom(ib)%yc(j).lt.((yen-yst)/2)) then
             dom(ib)%u(i,j,k) = ubulk*(1.0d0+1.0d0/7.0d0)
     &	      *(DABS(2*dom(ib)%yc(j)/(yen-yst)))**(1.d0/7.d0)
 	  else
             dom(ib)%u(i,j,k) = ubulk*(1.0d0+1.0d0/7.0d0)
     &	 *(DABS(2*((yen-yst)-dom(ib)%yc(j))/(yen-yst)))**(1.d0/7.d0)
	  endif
            dom(ib)%u(i,j,k) = dom(ib)%u(i,j,k)*(1.0d0+1.0d0/7.0d0)
     &	 *(DABS(dom(ib)%zc(k)/(zen-zst)))**(1.d0/7.d0)
	     enddo ; end do ;  end do
          END IF
!.######### U=> When power law inlet condition, 7 Dic 2015 .##########
          IF (dom(ib)%bc_west.eq.13) THEN			
           do i = dom(ib)%isu-1,dom(ib)%ieu+1 
		do j = dom(ib)%jsu-1,dom(ib)%jeu+1
		 do k = dom(ib)%ksu-1,dom(ib)%keu+1
	  if (dom(ib)%yc(j).lt.((yen-yst)/2)) then
             dom(ib)%u(i,j,k) = ubulk*(1.0d0+1.0d0/7.0d0)
     &	      *(DABS(2*dom(ib)%yc(j)/(yen-yst)))**(1.d0/7.d0)
 	  else
             dom(ib)%u(i,j,k) = ubulk*(1.0d0+1.0d0/7.0d0)
     &	 *(DABS(2*((yen-yst)-dom(ib)%yc(j))/(yen-yst)))**(1.d0/7.d0)
	  endif
	     enddo ; end do ;  end do
          END IF

           end if	!No restart

!	     Allocate time series 
		
	     jtime=itime_end-ntime

	     if (ntime*dt.lt.t_start_averaging2) then
			jtime=itime_end-INT(t_start_averaging2/dt)+1	
	     endif

	     allocate(dom(ib)%u_unst(n_unstpt,jtime))
	     allocate(dom(ib)%v_unst(n_unstpt,jtime))
	     allocate(dom(ib)%w_unst(n_unstpt,jtime))
	     allocate(dom(ib)%um_unst(n_unstpt,jtime))
	     allocate(dom(ib)%vm_unst(n_unstpt,jtime))
	     allocate(dom(ib)%wm_unst(n_unstpt,jtime))
	     allocate(dom(ib)%p_unst(n_unstpt,jtime))
	     allocate(dom(ib)%pm_unst(n_unstpt,jtime))
	     allocate(dom(ib)%ksgs_unst(n_unstpt,jtime))
	     allocate(dom(ib)%eps_unst(n_unstpt,jtime))
        allocate(dom(ib)%T_unst(n_unstpt,jtime)) !Aleks 04/24
        allocate(dom(ib)%Tm_unst(n_unstpt,jtime)) !Aleks 04/24

        end do

!.################################################
!.###########  Synthetic Eddy Method, 14 Dic 2015    ##########
          IF (bc_w.eq.8 .and. myrank.eq.0) then
		print*,'Writing the SEM inlet'
		call SEM  !Generate the files for the inlet turbulent field
		print*,'Finish the SEM inlet'
	    ENDIF

70      format (10e25.8)
71      format (3F15.6)

        end subroutine 
!##########################################################################
