      SUBROUTINE GMG
**********************************************************
*     Gent and McWilliams, 1990, eddy transport of tracer.
*     Griffies, 1998 skew flux formulation.
*     Boundary conditions - zero flux.
*     Version 30.04.2011.
**********************************************************

      INCLUDE 'slo2.fi'
      common /si/ s0,sm,sp,s1,s2,s3,s4,s5,s6,asr,asr2
      common /diffus/ al,alt
	common /consts/ c3,c6,c9,c12,c18,Rhx,R2hx2
      INCLUDE 'tparm.fi'

ccc	write(*,*) nt3(12,47,10), nt3(12,48,10), nt3(12,49,10)

	Agm= 0.25*ALT  ! Gent-McWilliams turbulence coefficient

	c6= 1./6.
	c3= 1./3.
	c9 =c3*c3
	c12=0.5*c6
	c18=c3*c6
	c24=0.5*c12
      asr=hx/hy
	asr2=asr*asr
	R2=R*R
	Rhx=R*hx
      HXX= 1./HX
      HYY= 1./HY
      A= Agm *.5*HXX*HYY

*     Runge-Kutta predictor-corrector time stepping.

      DO iRK=1,2

      DO 1 J=1,JL
      S0=SI(J)
      SM=SI(J-1)
      SP=SI(J+1)
      S1=c3*(2.*S0+SM)
      S2=c3*(2.*SM+S0)
      S3=S1
      S4=c3*(2.*S0+SP)
      S5=c3*(2.*SP+S0)
      S6=S4
      r2s06= c6*R2*S0
                     
      DO 1 I=1,IL
      KB = KM2(I,J)


c      IF(nt3(i,j,1).GT.0) THEN
      IF(KB.GT.0) THEN

*-------------------------------------------------
*         Surface and Nonbottom points
*-------------------------------------------------
      DO 2 K=1, KB -1
      n= abs(nt3(i,j,k))
      np=abs(nt3(i,j,k+1))

	hzk = hz(k)

      IF( k .EQ. 1) THEN
        hzk1= 0.
      ELSE
        hzk1= hz(k-1)
      END IF

	if(iRK .EQ. 1) then
      CA=   DT/(R2S06*(CG(n)*HZK1+CG(np)*HZK))
	else
      CA=2.*DT/(R2S06*(CG(n)*HZK1+CG(np)*HZK))
	endif

      IF( iRK .EQ. 1) then
      call SkewFlux(Tm2,Ropot,hz,i,j,k,N,NP,DIFT,DIFTP,KB,
     &              il1,jl1,kl,klp,
     &              KT,hx,hy,r,z)
      call SkewFlux(Sm2,Ropot,hz,i,j,k,N,NP,DIFS,DIFSP,KB,
     &              il1,jl1,kl,klp,
     &              KT,hx,hy,r,z)
	else
      call SkewFlux(Tm1,Ropot,hz,i,j,k,N,NP,DIFT,DIFTP,KB,
     &              il1,jl1,kl,klp,
     &              KT,hx,hy,r,z)
      call SkewFlux(Sm1,Ropot,hz,i,j,k,N,NP,DIFS,DIFSP,KB,
     &              il1,jl1,kl,klp,
     &              KT,hx,hy,r,z)
      end if

      DIFT =A*DIFT
      DIFTP=A*DIFTP
      DIFS =A*DIFS
      DIFSP=A*DIFSP

      IF( iRK .EQ. 1) then
      Tm1(I,J,K)=TM2(I,J,K)  +CA*(DIFT+DIFTP)
      Sm1(I,J,K)=SM2(I,J,K)  +CA*(DIFS+DIFSP)
	Sm1(i,j,k)=MAX(Sm1(i,j,k),0.)
	Tm1(i,j,k)=MAX(Tm1(i,j,k),Tfr(Sm1(i,j,k),0.) )
	else
      T  (I,J,K)=TM2(I,J,K)  +CA*(DIFT+DIFTP)
      S  (I,J,K)=SM2(I,J,K)  +CA*(DIFS+DIFSP)
	S  (i,j,k)=MAX(S  (i,j,k),0.)
	T  (i,j,k)=MAX(T  (i,j,k),Tfr(S  (i,j,k),0.) )
	end if

2     CONTINUE
*     --------------- Bottom ------------------

	N = NP

	if(iRK .EQ. 1) then
      CA=    DT/(R2s06*CG(n)*HZ(KB-1))
	else
      CA= 2.*DT/(R2s06*CG(n)*HZ(KB-1))
	endif

      IF( iRK .EQ. 1) then
      call SkewFlux(Tm2,Ropot,hz,i,j,kb,N,NP,DIFT,DIFTP,KB,
     &              il1,jl1,kl,klp,
     &              KT,hx,hy,r,z)
      call SkewFlux(Sm2,Ropot,hz,i,j,kb,N,NP,DIFS,DIFSP,KB,
     &              il1,jl1,kl,klp,
     &              KT,hx,hy,r,z)
	else
      call SkewFlux(Tm1,Ropot,hz,i,j,kb,N,NP,DIFT,DIFTP,KB,
     &              il1,jl1,kl,klp,
     &              KT,hx,hy,r,z)
      call SkewFlux(Sm1,Ropot,hz,i,j,kb,N,NP,DIFS,DIFSP,KB,
     &              il1,jl1,kl,klp,
     &              KT,hx,hy,r,z)
      end if

      DIFT=A*DIFT
      DIFS=A*DIFS
      IF( iRK .EQ. 1) then
      Tm1(I,J,KB)=TM2(I,J,KB)  +CA*DIFT
      Sm1(I,J,KB)=SM2(I,J,KB)  +CA*DIFS
	Sm1(i,j,kb)=MAX(Sm1(i,j,kb),0.)
	Tm1(i,j,kb)=MAX(Tm1(i,j,kb),Tfr(Sm1(i,j,kb),0.) )
	else
      T  (I,J,KB)=TM2(I,J,KB)  +CA*DIFT
      S  (I,J,KB)=SM2(I,J,KB)  +CA*DIFS
	S  (i,j,kb)=MAX(S  (i,j,kb),0.)
	T  (i,j,kb)=MAX(T  (i,j,kb),Tfr(S  (i,j,kb),0.) )
	end if


      END IF
1     CONTINUE

      END DO    ! Runge-Kutta predictor-corrector steps.

      RETURN
      END

      SUBROUTINE 
     & 	SkewFlux(T,Ro,hz,i,j,k,N,NP,DIFT,DIFTP,KB,il1,jl1,kl,klp,
     &             KT,hx,hy,r,z)
*     Version 26.11.2010.
*     Tapering by Danabasoglu and McWilliams, JC, 1995 (F1)
*     and Large, Danabasoglu and Doney, JPO, 1997 (F2).

*     Or, more simple, Gerdes et.al., 1991 (F1)

      Parameter (Smax  = 1.e-2)   ! Maximum slope
	Parameter (Rossby= 1.4e6)   ! c/f, c=200cm/s, Rossby radius

      dimension T(0:il1,0:jl1,kl), Ro(0:il1,0:jl1,kl), KT(6,13), hz(kl)
     &          , z(klp)
      common /si/ s0,sm,sp,s1,s2,s3,s4,s5,s6,asr,asr2
	common /consts/ c3,c6,c9,c12,c18,Rhx,R2hx2
      real KT

	Rhy=Rhx/asr
	km=k-1
	kp=k+1
	
      DIFT=0.
      DIFTP=0.

      Q1K=(T(i,j,k)+T(i+1,j,k)+T(i+1,j-1,k))
      Q2K=(T(i,j,k)+T(i+1,j-1,k)+T(i,j-1,k))
      Q3K=(T(i,j,k)+T(i-1,j,k)+T(i,j-1,k))
      Q4K=(T(i,j,k)+T(i-1,j,k)+T(i-1,j+1,k))
      Q5K=(T(i,j,k)+T(i,j+1,k)+T(i-1,j+1,k))
      Q6K=(T(i,j,k)+T(i+1,j,k)+T(i,j+1,k))

      Ro1K= Ro(i,j,k )+Ro(i+1,j,k )+Ro(i+1,j-1,k )
      Ro2K =Ro(i,j,k )+Ro(i+1,j-1,k )+Ro(i,j-1,k )
      Ro3K =Ro(i,j,k )+Ro(i-1,j,k )+Ro(i,j-1,k )
      Ro4K =Ro(i,j,k )+Ro(i-1,j,k )+Ro(i-1,j+1,k )
      Ro5K= Ro(i,j,k )+Ro(i,j+1,k )+Ro(i-1,j+1,k )
      Ro6K= Ro(i,j,k )+Ro(i+1,j,k )+Ro(i,j+1,k )

      IF( K .GT. 1) THEN    !     UPPER HALF

      Q1Km=(T(i,j,km)+T(i+1,j,km)+T(i+1,j-1,km))
      Q2Km=(T(i,j,km)+T(i+1,j-1,km)+T(i,j-1,km))
      Q3Km=(T(i,j,km)+T(i-1,j,km)+T(i,j-1,km))
      Q4Km=(T(i,j,km)+T(i-1,j,km)+T(i-1,j+1,km))
      Q5Km=(T(i,j,km)+T(i,j+1,km)+T(i-1,j+1,km))
      Q6Km=(T(i,j,km)+T(i+1,j,km)+T(i,j+1,km))

      Ro1Km=Ro(i,j,km)+Ro(i+1,j,km)+Ro(i+1,j-1,km)
      Ro2Km=Ro(i,j,km)+Ro(i+1,j-1,km)+Ro(i,j-1,km)
      Ro3Km=Ro(i,j,km)+Ro(i-1,j,km)+Ro(i,j-1,km)
      Ro4Km=Ro(i,j,km)+Ro(i-1,j,km)+Ro(i-1,j+1,km)
      Ro5Km=Ro(i,j,km)+Ro(i,j+1,km)+Ro(i-1,j+1,km)
      Ro6Km=Ro(i,j,km)+Ro(i+1,j,km)+Ro(i,j+1,km)

c     Triangle # 1.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(km)*(Ro(i+1,j,k )-Ro(i,j,k )+
     &                  Ro(i+1,j,km)-Ro(i,j,km))/
     &       (max(1.e-9,(Ro1k-Ro1km))*Rhx*S1)
	agm23= -1.5*hz(km)*(Ro(i+1,j,k )-Ro(i+1,j-1,k )+
     &                  Ro(i+1,j,km)-Ro(i+1,j-1,km))/
     &       (max(1.e-9,(Ro1k-Ro1km))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then ! Gerdes, et.al., 1991
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul))) !Danabasoglu and McWilliams, 1995

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(km))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))

	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23

c     dT/dz*dfi/dlambda
      DIFT= DIFT -KT(1,n)*Rhy*c6*agm13*(Q1K-Q1Km)
c     dT/dlambda*dfi/dz 
      DIFT= DIFT -KT(1,n)*Rhy*c12*agm13*(T(i+1,j,k )-T(i,j,k)+
     &                                 T(i+1,j,km)-T(i,j,km))
c     dfi/dz*dT/dteta
      DIFT= DIFT -KT(1,n)*Rhx*c12*S1*agm23*(T(i+1,j,k )-T(i+1,j-1,k)+
     &                                    T(i+1,j,km)-T(i+1,j-1,km))

c     Triangle # 2.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(km)*(Ro(i+1,j-1,k )-Ro(i,j-1,k )+
     &                  Ro(i+1,j-1,km)-Ro(i,j-1,km))/
     &       (max(1.e-9,(Ro2k-Ro2km))*Rhx*S2)
	agm23= -1.5*hz(km)*(Ro(i,j,k )-Ro(i,j-1,k )+
     &                  Ro(i,j,km)-Ro(i,j-1,km))/
     &       (max(1.e-9,(Ro2k-Ro2km))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(km))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dlambda*dfi/dz
      DIFT= DIFT -KT(2,n)*Rhy*c12*agm13*(T(i+1,j-1,k )-T(i,j-1,k)+
     &                                 T(i+1,j-1,km)-T(i,j-1,km))
c     dT/dz*dfi/dteta
      DIFT= DIFT +KT(2,n)*Rhx*S2*c6*agm23*(Q2K-Q2Km)
c     dfi/dz*dT/dteta
      DIFT= DIFT -KT(2,n)*Rhx*c12*S2*agm23*(T(i,j,k )-T(i,j-1,k)+
     &                                    T(i,j,km)-T(i,j-1,km))

c     Triangle # 3.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(km)*(Ro(i,j,k )-Ro(i-1,j,k )+
     &                  Ro(i,j,km)-Ro(i-1,j,km))/
     &       (max(1.e-9,(Ro3k-Ro3km))*Rhx*S3)
	agm23= -1.5*hz(km)*(Ro(i,j,k )-Ro(i,j-1,k )+
     &                  Ro(i,j,km)-Ro(i,j-1,km))/
     &       (max(1.e-9,(Ro3k-Ro3km))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(km))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dz*dfi/dlambda
      DIFT= DIFT +KT(3,n)*Rhy*c6*agm13*(Q3K-Q3Km)
c     dT/dlambda*dfi/dz
      DIFT= DIFT -KT(3,n)*Rhy*c12*agm13*(T(i,j,k )-T(i-1,j,k)+
     &                                 T(i,j,km)-T(i-1,j,km))
c     dT/dz*dfi/dteta
      DIFT= DIFT +KT(3,n)*Rhx*S3*c6*agm23*(Q3K-Q3Km)
c     dfi/dz*dT/dteta
      DIFT= DIFT -KT(3,n)*Rhx*c12*S3*agm23*(T(i,j,k )-T(i,j-1,k)+
     &                                    T(i,j,km)-T(i,j-1,km))

c     Triangle # 4.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(km)*(Ro(i,j,k )-Ro(i-1,j,k )+
     &                  Ro(i,j,km)-Ro(i-1,j,km))/
     &       (max(1.e-9,(Ro4k-Ro4km))*Rhx*S4)
	agm23= -1.5*hz(km)*(Ro(i-1,j+1,k )-Ro(i-1,j,k )+
     &                  Ro(i-1,j+1,km)-Ro(i-1,j,km))/
     &       (max(1.e-9,(Ro4k-Ro4km))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(km))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dz*dfi/dlambda
      DIFT= DIFT +KT(4,n)*Rhy*c6*agm13*(Q4K-Q4Km)
c     dT/dlambda*dfi/dz
      DIFT= DIFT -KT(4,n)*Rhy*c12*agm13*(T(i,j,k )-T(i-1,j,k)+
     &                                 T(i,j,km)-T(i-1,j,km))
c     dfi/dz*dT/dteta
      DIFT= DIFT -KT(4,n)*Rhx*c12*S4*agm23*(T(i-1,j+1,k )-T(i-1,j,k)+
     &                                    T(i-1,j+1,km)-T(i-1,j,km))

c     Triangle # 5.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(km)*(Ro(i,j+1,k )-Ro(i-1,j+1,k )+
     &                  Ro(i,j+1,km)-Ro(i-1,j+1,km))/
     &       (max(1.e-9,(Ro5k-Ro5km))*Rhx*S5)
	agm23= -1.5*hz(km)*(Ro(i,j+1,k )-Ro(i,j,k )+
     &                  Ro(i,j+1,km)-Ro(i,j,km))/
     &       (max(1.e-9,(Ro5k-Ro5km))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(km))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dlambda*dfi/dz
      DIFT= DIFT -KT(5,n)*Rhy*c12*agm13*(T(i,j+1,k )-T(i-1,j+1,k)+
     &                                 T(i,j+1,km)-T(i-1,j+1,km))
c     dT/dz*dfi/dteta
      DIFT= DIFT -KT(5,n)*Rhx*S5*c6*agm23*(Q5K-Q5Km)
c     dfi/dz*dT/dteta
      DIFT= DIFT -KT(5,n)*Rhx*c12*S5*agm23*(T(i,j+1,k )-T(i,j,k)+
     &                                    T(i,j+1,km)-T(i,j,km))

c     Triangle # 6.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(km)*(Ro(i+1,j,k )-Ro(i,j,k )+
     &                  Ro(i+1,j,km)-Ro(i,j,km))/
     &       (max(1.e-9,(Ro6k-Ro6km))*Rhx*S6)
	agm23= -1.5*hz(km)*(Ro(i,j+1,k )-Ro(i,j,k )+
     &                  Ro(i,j+1,km)-Ro(i,j,km))/
     &       (max(1.e-9,(Ro6k-Ro6km))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(km))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dz*dfi/dlambda
      DIFT= DIFT -KT(6,n)*Rhy*c6*agm13*(Q6K-Q6Km)
c     dT/dlambda*dfi/dz
      DIFT= DIFT -KT(6,n)*Rhy*c12*agm13*(T(i+1,j,k )-T(i,j,k)+
     &                                 T(i+1,j,km)-T(i,j,km))
c     dT/dz*dfi/dteta
      DIFT= DIFT -KT(6,n)*Rhx*S6*c6*agm23*(Q6K-Q6Km)
c     dfi/dz*dT/dteta
      DIFT= DIFT -KT(6,n)*Rhx*c12*S6*agm23*(T(i,j+1,k )-T(i,j,k)+
     &                                    T(i,j+1,km)-T(i,j,km))

      END IF

      IF( K .LT. KB) THEN    !     LOWER HALF

      Q1Kp=(T(i,j,kp)+T(i+1,j,kp)+T(i+1,j-1,kp))
      Q2Kp=(T(i,j,kp)+T(i+1,j-1,kp)+T(i,j-1,kp))
      Q3Kp=(T(i,j,kp)+T(i-1,j,kp)+T(i,j-1,kp))
      Q4Kp=(T(i,j,kp)+T(i-1,j,kp)+T(i-1,j+1,kp))
      Q5Kp=(T(i,j,kp)+T(i,j+1,kp)+T(i-1,j+1,kp))
      Q6Kp=(T(i,j,kp)+T(i+1,j,kp)+T(i,j+1,kp))

      Ro1Kp=Ro(i,j,kp)+Ro(i+1,j,kp)+Ro(i+1,j-1,kp)
      Ro2Kp=Ro(i,j,kp)+Ro(i+1,j-1,kp)+Ro(i,j-1,kp)
      Ro3Kp=Ro(i,j,kp)+Ro(i-1,j,kp)+Ro(i,j-1,kp)
      Ro4Kp=Ro(i,j,kp)+Ro(i-1,j,kp)+Ro(i-1,j+1,kp)
      Ro5Kp=Ro(i,j,kp)+Ro(i,j+1,kp)+Ro(i-1,j+1,kp)
      Ro6Kp=Ro(i,j,kp)+Ro(i+1,j,kp)+Ro(i,j+1,kp)

c     Triangle # 1.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(k)*(Ro(i+1,j,k )-Ro(i,j,k )+
     &                 Ro(i+1,j,kp)-Ro(i,j,kp))/
     &       (max(1.e-9,(Ro1kp-Ro1k))*Rhx*S1)
	agm23= -1.5*hz(k)*(Ro(i+1,j,k )-Ro(i+1,j-1,k )+
     &                 Ro(i+1,j,kp)-Ro(i+1,j-1,kp))/
     &       (max(1.e-9,(Ro1kp-Ro1k))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(kp))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dz*dfi/dlambda
      DIFTP= DIFTP -KT(1,np)*Rhy*c6*agm13*(Q1Kp-Q1K)
c     dT/dlambda*dfi/dz
      DIFTP= DIFTP +KT(1,np)*Rhy*c12*agm13*(T(i+1,j,k )-T(i,j,k)+
     &                                    T(i+1,j,kp)-T(i,j,kp))
c     dfi/dz*dT/dteta
      DIFTP=DIFTP +KT(1,np)*Rhx*c12*S1*agm23*(T(i+1,j,k )-T(i+1,j-1,k)+
     &                                      T(i+1,j,kp)-T(i+1,j-1,kp))

c     Triangle # 2.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(k)*(Ro(i+1,j-1,k )-Ro(i,j-1,k )+
     &                 Ro(i+1,j-1,kp)-Ro(i,j-1,kp))/
     &       (max(1.e-9,(Ro2kp-Ro2k))*Rhx*S2)
	agm23= -1.5*hz(k)*(Ro(i,j,k )-Ro(i,j-1,k )+
     &                 Ro(i,j,kp)-Ro(i,j-1,kp))/
     &       (max(1.e-9,(Ro2kp-Ro2k))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(kp))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dlambda*dfi/dz
      DIFTP= DIFTP +KT(2,np)*Rhy*c12*agm13*(T(i+1,j-1,k )-T(i,j-1,k)+
     &                                    T(i+1,j-1,kp)-T(i,j-1,kp))
c     dT/dz*dfi/dteta
      DIFTP= DIFTP +KT(2,np)*Rhx*S2*c6*agm23*(Q2Kp-Q2K)
c     dfi/dz*dT/dteta
      DIFTP= DIFTP +KT(2,np)*Rhx*c12*S2*agm23*(T(i,j,k )-T(i,j-1,k)+
     &                                       T(i,j,kp)-T(i,j-1,kp))

c     Triangle # 3.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(k)*(Ro(i,j,k )-Ro(i-1,j,k )+
     &                 Ro(i,j,kp)-Ro(i-1,j,kp))/
     &       (max(1.e-9,(Ro3kp-Ro3k))*Rhx*S3)
	agm23= -1.5*hz(k)*(Ro(i,j,k )-Ro(i,j-1,k )+
     &                 Ro(i,j,kp)-Ro(i,j-1,kp))/
     &       (max(1.e-9,(Ro3kp-Ro3k))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(kp))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dz*dfi/dlambda
      DIFTP= DIFTP +KT(3,np)*Rhy*c6*agm13*(Q3Kp-Q3K)
c     dT/dlambda*dfi/dz
      DIFTP= DIFTP +KT(3,np)*Rhy*c12*agm13*(T(i,j,k )-T(i-1,j,k)+
     &                                    T(i,j,kp)-T(i-1,j,kp))
c     dT/dz*dfi/dteta
      DIFTP= DIFTP +KT(3,np)*Rhx*S3*c6*agm23*(Q3Kp-Q3K)
c     dfi/dz*dT/dteta
      DIFTP= DIFTP +KT(3,np)*Rhx*c12*S3*agm23*(T(i,j,k )-T(i,j-1,k)+
     &                                       T(i,j,kp)-T(i,j-1,kp))

c     Triangle # 4.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(k)*(Ro(i,j,k )-Ro(i-1,j,k )+
     &                 Ro(i,j,kp)-Ro(i-1,j,kp))/
     &       (max(1.e-9,(Ro4kp-Ro4k))*Rhx*S4)
	agm23= -1.5*hz(k)*(Ro(i-1,j+1,k )-Ro(i-1,j,k )+
     &                 Ro(i-1,j+1,kp)-Ro(i-1,j,kp))/
     &       (max(1.e-9,(Ro4kp-Ro4k))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(kp))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dz*dfi/dlambda
      DIFTP= DIFTP +KT(4,np)*Rhy*c6*agm13*(Q4Kp-Q4K)
c     dT/dlambda*dfi/dz
      DIFTP= DIFTP +KT(4,np)*Rhy*c12*agm13*(T(i,j,k )-T(i-1,j,k)+
     &                                    T(i,j,kp)-T(i-1,j,kp))
c     dfi/dz*dT/dteta
      DIFTP=DIFTP +KT(4,np)*Rhx*c12*S4*agm23*(T(i-1,j+1,k )-T(i-1,j,k)+
     &                                      T(i-1,j+1,kp)-T(i-1,j,kp))

c     Triangle # 5.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(k)*(Ro(i,j+1,k )-Ro(i-1,j+1,k )+
     &                 Ro(i,j+1,kp)-Ro(i-1,j+1,kp))/
     &       (max(1.e-9,(Ro5kp-Ro5k))*Rhx*S5)
	agm23= -1.5*hz(k)*(Ro(i,j+1,k )-Ro(i,j,k )+
     &                 Ro(i,j+1,kp)-Ro(i,j,kp))/
     &       (max(1.e-9,(Ro5kp-Ro5k))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(kp))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	else
	z0= 1.
	end if
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dlambda*dfi/dz
      DIFTP= DIFTP +KT(5,np)*Rhy*c12*agm13*(T(i,j+1,k )-T(i-1,j+1,k)+
     &                                    T(i,j+1,kp)-T(i-1,j+1,kp))
c     dT/dz*dfi/dteta
      DIFTP= DIFTP -KT(5,np)*Rhx*S5*c6*agm23*(Q5Kp-Q5K)
c     dfi/dz*dT/dteta
      DIFTP= DIFTP +KT(5,np)*Rhx*c12*S5*agm23*(T(i,j+1,k )-T(i,j,k)+
     &                                       T(i,j+1,kp)-T(i,j,kp))

c     Triangle # 6.
*     Skew flux coefficients tensor 
      agm13= -1.5*hz(k)*(Ro(i+1,j,k )-Ro(i,j,k )+
     &                 Ro(i+1,j,kp)-Ro(i,j,kp))/
     &       (max(1.e-9,(Ro6kp-Ro6k))*Rhx*S6)
	agm23= -1.5*hz(k)*(Ro(i,j+1,k )-Ro(i,j,k )+
     &                 Ro(i,j+1,kp)-Ro(i,j,kp))/
     &       (max(1.e-9,(Ro6kp-Ro6k))*Rhy)
	Smodul= sqrt(agm13**2+agm23**2)
	F1=1.0
	if(Smodul .GT. Smax) then
	F1= (Smax/Smodul)**2
	end if
ccc	F1= 0.5*(1.0+TANH(1.e3*(Smax-Smodul)))

	Depth= Rossby*MAX(1.e-9,Smodul)
	zlevel= 0.5*(z(k)+z(kp))
	if(zlevel .LE. Depth) then 
	z0= zlevel/Depth
	else
	z0= 1.
	end if
	F2= 0.5*(1.0+SIND(180.*(z0-0.5)))
	F1= F1*F2
	agm13= F1*agm13
	agm23= F1*agm23
c     dT/dz*dfi/dlambda
      DIFTP= DIFTP -KT(6,np)*Rhy*c6*agm13*(Q6Kp-Q6K)
c     dT/dlambda*dfi/dz
      DIFTP= DIFTP +KT(6,np)*Rhy*c12*agm13*(T(i+1,j,k )-T(i,j,k)+
     &                                    T(i+1,j,kp)-T(i,j,kp))
c     dT/dz*dfi/dteta
      DIFTP= DIFTP -KT(6,np)*Rhx*S6*c6*agm23*(Q6Kp-Q6K)

c     dfi/dz*dT/dteta
      DIFTP= DIFTP +KT(6,np)*Rhx*c12*S6*agm23*(T(i,j+1,k )-T(i,j,k)+
     &                                       T(i,j+1,kp)-T(i,j,kp))

      END IF
      RETURN
      END
