      SUBROUTINE PULL2(PK,SIG,FINV,DET,NDI)
C>       PULL-BACK TIMES DET OF A 2ND ORDER TENSOR
       IMPLICIT NONE
       INCLUDE 'PARAM_UMAT.INC'
C
       INTEGER I1,J1,II1,JJ1,NDI
       DOUBLE PRECISION PK(NDI,NDI),FINV(NDI,NDI)
       DOUBLE PRECISION SIG(NDI,NDI)
       DOUBLE PRECISION AUX,DET
C
       DO I1=1,NDI
        DO J1=1,NDI
          AUX=ZERO
         DO II1=1,NDI
          DO JJ1=1,NDI
            AUX=AUX+DET*FINV(I1,II1)*FINV(J1,JJ1)*SIG(II1,JJ1)
         END DO
        END DO
           PK(I1,J1)=AUX
        END DO
       END DO
C
       RETURN
      END SUBROUTINE PULL2
      SUBROUTINE METVOL(CVOL,C,PV,PPV,DET,NDI)
C>    VOLUMETRIC MATERIAL ELASTICITY TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1,K1,L1
      DOUBLE PRECISION C(NDI,NDI),CINV(NDI,NDI),
     1                 CVOL(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION PV,PPV,DET
C
      CALL MATINV3D(C,CINV,NDI)
C
      DO I1 = 1, NDI
        DO J1 = 1, NDI
         DO K1 = 1, NDI
           DO L1 = 1, NDI
             CVOL(I1,J1,K1,L1)=
     1                 DET*PPV*CINV(I1,J1)*CINV(K1,L1)
     2           -DET*PV*(CINV(I1,K1)*CINV(J1,L1)
     3                      +CINV(I1,L1)*CINV(J1,K1))
           END DO
         END DO
        END DO
      END DO
C
      RETURN
      END SUBROUTINE METVOL
      SUBROUTINE CONTRACTION42(S,LT,RT,NDI)
C>       DOUBLE CONTRACTION BETWEEN 4TH ORDER AND 2ND ORDER  TENSOR
C>      INPUT:
C>       LT - RIGHT 4TH ORDER TENSOR
C>       RT - LEFT  2ND ODER TENSOR
C>      OUTPUT:
C>       S - DOUBLE CONTRACTED TENSOR (2ND ORDER)
       IMPLICIT NONE
       INCLUDE 'PARAM_UMAT.INC'
C
       INTEGER I1,J1,K1,L1,NDI
C
       DOUBLE PRECISION RT(NDI,NDI),LT(NDI,NDI,NDI,NDI)
       DOUBLE PRECISION S(NDI,NDI)
       DOUBLE PRECISION AUX
C
       DO I1=1,NDI
        DO J1=1,NDI
          AUX=ZERO
         DO K1=1,NDI
          DO L1=1,NDI
            AUX=AUX+LT(I1,J1,K1,L1)*RT(K1,L1)
         END DO
        END DO
           S(I1,J1)=AUX
       END DO
      END DO
       RETURN
      END SUBROUTINE CONTRACTION42
C>********************************************************************
C> Record of revisions:                                              |
C>        Date        Programmer        Description of change        |
C>        ====        ==========        =====================        |
C>     15/11/2017    Joao Ferreira      cont mech general eqs        |
C>     01/11/2018    Joao Ferreira      comments added               |
C>--------------------------------------------------------------------
C>     Description:
C>     UMAT: IMPLEMENTATION OF THE CONSTITUTIVE EQUATIONS BASED UPON 
C>     A STRAIN-ENERGY FUNCTION (SEF).
C>     THIS CODE, AS IS, EXPECTS A SEF BASED ON THE INVARIANTS OF THE 
C>     CAUCHY-GREEN TENSORS. A VISCOELASTIC COMPONENT IS ALSO 
C>     INCLUDED IF NEEDED. 
C>     YOU CAN CHOOSE TO COMPUTE AT THE MATERIAL FRAME AND THEN 
C>     PUSHFORWARD OR  COPUTE AND THE SPATIAL FRAME DIRECTLY.
C>--------------------------------------------------------------------
C>     IF YOU WANT TO ADAPT THE CODE ACCORDING TO YOUR SEF:
C>    ISOMAT - DERIVATIVES OF THE SEF IN ORDER TO THE INVARIANTS
C>    ADD OTHER CONTRIBUTIONS: STRESS AND TANGENT MATRIX
C>-------------------------------------------------------------------- 
C      STATE VARIABLES: CHECK ROUTINES - INITIALIZE, WRITESDV, READSDV.
C>--------------------------------------------------------------------              
C>     UEXTERNALDB: READ FILAMENTS ORIENTATION AND PREFERED DIRECTION
C>--------------------------------------------------------------------
C>---------------------------------------------------------------------
      SUBROUTINE UMAT(STRESS,STATEV,DDSDDE,SSE,SPD,SCD,
     1 RPL,DDSDDT,DRPLDE,DRPLDT,
     2 STRAN,DSTRAN,TIME,DTIME,TEMP,DTEMP,PREDEF,DPRED,CMNAME,
     3 NDI,NSHR,NTENS,NSTATEV,PROPS,NPROPS,COORDS,DROT,PNEWDT,
     4 CELENT,DFGRD0,DFGRD1,NOEL,NPT,LAYER,KSPT,KSTEP,KINC)
C
C----------------------------------------------------------------------
C--------------------------- DECLARATIONS -----------------------------
C----------------------------------------------------------------------
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C     ADD COMMON BLOCKS HERE IF NEEDED (and in uexternal)
C      COMMON /KBLOCK/KBLOCK
C
      CHARACTER*8 CMNAME
C
      INTEGER NDI, NSHR, NTENS, NSTATEV, NPROPS, NOEL, NPT,
     1        LAYER, KSPT, KSTEP, KINC
C     
      DOUBLE PRECISION STRESS(NTENS),STATEV(NSTATEV),
     1 DDSDDE(NTENS,NTENS),DDSDDT(NTENS),DRPLDE(NTENS),
     2 STRAN(NTENS),DSTRAN(NTENS),TIME(2),PREDEF(1),DPRED(1),
     3 PROPS(NPROPS),COORDS(3),DROT(3,3),DFGRD0(3,3),DFGRD1(3,3),
     4 FIBORI(NELEM,4)
C
      DOUBLE PRECISION SSE, SPD, SCD, RPL, DRPLDT, DTIME, TEMP,
     1                 DTEMP,PNEWDT,CELENT
C
      INTEGER NTERM
C
C     FLAGS
C      INTEGER FLAG1
C     UTILITY TENSORS
      DOUBLE PRECISION UNIT2(NDI,NDI),UNIT4(NDI,NDI,NDI,NDI),
     1                 UNIT4S(NDI,NDI,NDI,NDI),
     2                 PROJE(NDI,NDI,NDI,NDI),PROJL(NDI,NDI,NDI,NDI)
C     KINEMATICS
      DOUBLE PRECISION DISTGR(NDI,NDI),C(NDI,NDI),B(NDI,NDI),
     1                 CBAR(NDI,NDI),BBAR(NDI,NDI),DISTGRINV(NDI,NDI),
     2                 UBAR(NDI,NDI),VBAR(NDI,NDI),ROT(NDI,NDI),
     3                 DFGRD1INV(NDI,NDI)
      DOUBLE PRECISION DET,CBARI1,CBARI2
C     VOLUMETRIC CONTRIBUTION
      DOUBLE PRECISION PKVOL(NDI,NDI),SVOL(NDI,NDI),
     1                 CVOL(NDI,NDI,NDI,NDI),CMVOL(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION KBULK,PV,PPV,SSEV
C     ISOCHORIC CONTRIBUTION
      DOUBLE PRECISION SISO(NDI,NDI),PKISO(NDI,NDI),PK2(NDI,NDI),
     1                 CISO(NDI,NDI,NDI,NDI),CMISO(NDI,NDI,NDI,NDI),
     2                 SFIC(NDI,NDI),CFIC(NDI,NDI,NDI,NDI),
     3                 PKFIC(NDI,NDI),CMFIC(NDI,NDI,NDI,NDI)
C     ISOCHORIC ISOTROPIC CONTRIBUTION
      DOUBLE PRECISION C10,C01,SSEISO,DISO(5),PKMATFIC(NDI,NDI),
     1                 SMATFIC(NDI,NDI),SISOMATFIC(NDI,NDI),
     2                 CMISOMATFIC(NDI,NDI,NDI,NDI),
     3                 CISOMATFIC(NDI,NDI,NDI,NDI)   
      DOUBLE PRECISION VORIF(3),VD(3),M0(3,3),MM(3,3),
     1        VORIF2(3),VD2(3),N0(3,3),NN(3,3)
C     VISCOUS PROPERTIES (GENERALIZED MAXWEL DASHPOTS)
      DOUBLE PRECISION VSCPROPS(6)
      INTEGER VV 
C     LIST VARS OF OTHER CONTRIBUTIONS HERE
C
C     JAUMMAN RATE CONTRIBUTION (REQUIRED FOR ABAQUS UMAT)
      DOUBLE PRECISION CJR(NDI,NDI,NDI,NDI)
C     CAUCHY STRESS AND ELASTICITY TENSOR
      DOUBLE PRECISION SIGMA(NDI,NDI),DDSIGDDE(NDI,NDI,NDI,NDI),
     1                                 DDPKDDE(NDI,NDI,NDI,NDI)
C     TESTING/DEBUG VARS
      DOUBLE PRECISION STEST(NDI,NDI), CTEST(NDI,NDI,NDI,NDI)
C----------------------------------------------------------------------
C-------------------------- INITIALIZATIONS ---------------------------
C----------------------------------------------------------------------
C     IDENTITY AND PROJECTION TENSORS
      UNIT2=ZERO
      UNIT4=ZERO
      UNIT4S=ZERO
      PROJE=ZERO
      PROJL=ZERO
C     KINEMATICS
      DISTGR=ZERO
      C=ZERO
      B=ZERO
      CBAR=ZERO
      BBAR=ZERO
      UBAR=ZERO
      VBAR=ZERO
      ROT=ZERO
      DET=ZERO
      CBARI1=ZERO
      CBARI2=ZERO
C     VOLUMETRIC
      PKVOL=ZERO
      SVOL=ZERO
      CVOL=ZERO
      KBULK=ZERO
      PV=ZERO
      PPV=ZERO
      SSEV=ZERO
C     ISOCHORIC
      SISO=ZERO
      PKISO=ZERO
      PK2=ZERO
      CISO=ZERO
      CFIC=ZERO
      SFIC=ZERO
      PKFIC=ZERO
C     ISOTROPIC
      C10=ZERO
      C01=ZERO
      SSEISO=ZERO
      DISO=ZERO
      PKMATFIC=ZERO
      SMATFIC=ZERO
      SISOMATFIC=ZERO
      CMISOMATFIC=ZERO
      CISOMATFIC=ZERO
C     INITIALIZE OTHER CONT HERE
C
C     JAUMANN RATE
      CJR=ZERO
C     TOTAL CAUCHY STRESS AND ELASTICITY TENSORS
      SIGMA=ZERO
      DDSIGDDE=ZERO
C
C----------------------------------------------------------------------
C------------------------ IDENTITY TENSORS ----------------------------
C----------------------------------------------------------------------
            CALL ONEM(UNIT2,UNIT4,UNIT4S,NDI)
C----------------------------------------------------------------------
C------------------- MATERIAL CONSTANTS AND DATA ----------------------
C----------------------------------------------------------------------
C     VOLUMETRIC
      KBULK    = PROPS(1)
C     ISOCHORIC ISOTROPIC MOONEY RIVLIN
      C10      = PROPS(2)
      C01      = PROPS(3)
C     VISCOUS EFFECTS: MAXWELL ELEMENTS (MAX:3)
      VV       = INT(PROPS(4))
      VSCPROPS = PROPS(5:10)

C     NUMERICAL COMPUTATIONS
      NTERM    = 60
C
C     STATE VARIABLES
C
      IF ((TIME(1).EQ.ZERO).AND.(KSTEP.EQ.1)) THEN
      CALL INITIALIZE(STATEV,VV)
      ENDIF
C        READ STATEV
      CALL SDVREAD(STATEV,VV)
C      
C----------------------------------------------------------------------
C---------------------------- KINEMATICS ------------------------------
C----------------------------------------------------------------------
C     DISTORTION GRADIENT
      CALL FSLIP(DFGRD1,DISTGR,DET,NDI)
C     INVERSE OF DISTORTION GRADIENT
      CALL MATINV3D(DFGRD1,DFGRD1INV,NDI)
C     INVERSE OF DISTORTION GRADIENT
      CALL MATINV3D(DISTGR,DISTGRINV,NDI)
C     CAUCHY-GREEN DEFORMATION TENSORS
      CALL DEFORMATION(DFGRD1,C,B,NDI)
      CALL DEFORMATION(DISTGR,CBAR,BBAR,NDI)      
C     INVARIANTS OF DEVIATORIC DEFORMATION TENSORS
      CALL INVARIANTS(CBAR,CBARI1,CBARI2,NDI)
C     STRETCH TENSORS
      CALL STRETCH(CBAR,BBAR,UBAR,VBAR,NDI)
C     ROTATION TENSORS
      CALL ROTATION(DISTGR,ROT,UBAR,NDI)
C     DEVIATORIC PROJECTION TENSORS
      CALL PROJEUL(UNIT2,UNIT4S,PROJE,NDI)
C
      CALL PROJLAG(C,UNIT4,PROJL,NDI)
C----------------------------------------------------------------------
C--------------------- CONSTITUTIVE RELATIONS  ------------------------
C----------------------------------------------------------------------
C
C---- VOLUMETRIC ------------------------------------------------------
C     STRAIN-ENERGY AND DERIVATIVES (CHANGE HERE ACCORDING TO YOUR MODEL)
      CALL VOL(SSEV,PV,PPV,KBULK,DET)
      CALL ISOMAT(SSEISO,DISO,C10,C01,CBARI1,CBARI2)
C
C---- ISOCHORIC ISOTROPIC ---------------------------------------------
C     PK2 'FICTICIOUS' STRESS TENSOR
      CALL PK2ISOMATFIC(PKMATFIC,DISO,CBAR,CBARI1,UNIT2,NDI)
C     CAUCHY 'FICTICIOUS' STRESS TENSOR
      CALL SIGISOMATFIC(SISOMATFIC,PKMATFIC,DISTGR,DET,NDI)
C     'FICTICIOUS' MATERIAL ELASTICITY TENSOR
      CALL CMATISOMATFIC(CMISOMATFIC,CBAR,CBARI1,CBARI2,
     1                          DISO,UNIT2,UNIT4,DET,NDI)
C     'FICTICIOUS' SPATIAL ELASTICITY TENSOR
      CALL CSISOMATFIC(CISOMATFIC,CMISOMATFIC,DISTGR,DET,NDI)
C
C----------------------------------------------------------------------
C     SUM OF ALL ELASTIC CONTRIBUTIONS
C----------------------------------------------------------------------
C     STRAIN-ENERGY
      SSE=SSEV+SSEISO
C     PK2 'FICTICIOUS' STRESS
      PKFIC=PKMATFIC
C     CAUCHY 'FICTICIOUS' STRESS
      SFIC=SISOMATFIC
C     MATERIAL 'FICTICIOUS' ELASTICITY TENSOR
      CMFIC=CMISOMATFIC
C     SPATIAL 'FICTICIOUS' ELASTICITY TENSOR
      CFIC=CISOMATFIC
C
C----------------------------------------------------------------------
C-------------------------- STRESS MEASURES ---------------------------
C----------------------------------------------------------------------
C
C---- VOLUMETRIC ------------------------------------------------------
C      PK2 STRESS
      CALL PK2VOL(PKVOL,PV,C,NDI)
C      CAUCHY STRESS
      CALL SIGVOL(SVOL,PV,UNIT2,NDI)
C
C---- ISOCHORIC -------------------------------------------------------
C      PK2 STRESS
      CALL PK2ISO(PKISO,PKFIC,PROJL,DET,NDI)
C      CAUCHY STRESS
      CALL SIGISO(SISO,SFIC,PROJE,NDI)
C
C---- VOLUMETRIC + ISOCHORIC ------------------------------------------
C      PK2 STRESS
      PK2   = PKVOL + PKISO
C      CAUCHY STRESS
      SIGMA = SVOL  + SISO
C
C----------------------------------------------------------------------
C-------------------- MATERIAL ELASTICITY TENSOR ----------------------
C----------------------------------------------------------------------
C
C---- VOLUMETRIC ------------------------------------------------------
C
      CALL METVOL(CMVOL,C,PV,PPV,DET,NDI)
C
C---- ISOCHORIC -------------------------------------------------------
C
      CALL METISO(CMISO,CMFIC,PROJL,PKISO,PKFIC,C,UNIT2,DET,NDI)
C
C----------------------------------------------------------------------
C
      DDPKDDE=  CMVOL + CMISO
C
C----------------------------------------------------------------------
C--------------------- SPATIAL ELASTICITY TENSOR ----------------------
C----------------------------------------------------------------------
C
C---- VOLUMETRIC ------------------------------------------------------
C
      CALL SETVOL(CVOL,PV,PPV,UNIT2,UNIT4S,NDI)
C
C---- ISOCHORIC -------------------------------------------------------
C
      CALL SETISO(CISO,CFIC,PROJE,SISO,SFIC,UNIT2,NDI)
C
C-----JAUMMAN RATE ----------------------------------------------------
C
      CALL SETJR(CJR,SIGMA,UNIT2,NDI)
C
C----------------------------------------------------------------------
C
C     ELASTICITY TENSOR
      DDSIGDDE=CVOL+CISO+CJR
C
C----------------------------------------------------------------------
C-------------------------- VISCOUS PART ------------------------------
C----------------------------------------------------------------------
C      PULLBACK OF STRESS AND ELASTICITY TENSORS
      CALL PULL2(PKVOL,SVOL,DFGRD1INV,DET,NDI)
      CALL PULL2(PKISO,SISO,DFGRD1INV,DET,NDI)
      CALL PULL4(CMVOL,CVOL,DFGRD1INV,DET,NDI)
      CALL PULL4(CMISO,CISO,DFGRD1INV,DET,NDI)
C      VISCOUS DAMPING 
      CALL VISCO(PK2,DDPKDDE,VV,PKVOL,PKISO,CMVOL,CMISO,DTIME,
     1                                        VSCPROPS,STATEV,NDI) 
C      PUSH FORWARD OF STRESS AND ELASTICITY TENSOR
      CALL PUSH2(SIGMA,PK2,DFGRD1,DET,NDI)
C
      CALL PUSH4(DDSIGDDE,DDPKDDE,DFGRD1,DET,NDI)
      DDSIGDDE=DDSIGDDE+CJR
C----------------------------------------------------------------------
C------------------------- INDEX ALLOCATION ---------------------------
C----------------------------------------------------------------------
C     VOIGT NOTATION  - FULLY SIMMETRY IMPOSED
      CALL INDEXX(STRESS,DDSDDE,SIGMA,DDSIGDDE,NTENS,NDI)
C
C----------------------------------------------------------------------
C--------------------------- STATE VARIABLES --------------------------
C----------------------------------------------------------------------
C     DO K1 = 1, NTENS
C      STATEV(1:27) = VISCOUS TENSORS
       CALL SDVWRITE(STATEV,DET,VV)
C     END DO
C----------------------------------------------------------------------
      RETURN
      END
C----------------------------------------------------------------------
C--------------------------- END OF UMAT ------------------------------
C----------------------------------------------------------------------
C
      SUBROUTINE PROJEUL(A,AA,PE,NDI)
C>    EULERIAN PROJECTION TENSOR
C      INPUTS:
C          IDENTITY TENSORS - A, AA
C      OUTPUTS:
C          4TH ORDER SYMMETRIC EULERIAN PROJECTION TENSOR - PE
C
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER I,J,K,L,NDI
C
      DOUBLE PRECISION A(NDI,NDI),AA(NDI,NDI,NDI,NDI),
     1                 PE(NDI,NDI,NDI,NDI)
C
      DO I=1,NDI
         DO J=1,NDI
          DO K=1,NDI
             DO L=1,NDI
              PE(I,J,K,L)=AA(I,J,K,L)-(ONE/THREE)*(A(I,J)*A(K,L))
           END DO
          END DO
        END DO
      END DO
C
      RETURN
      END SUBROUTINE PROJEUL
      SUBROUTINE SIGVOL(SVOL,PV,UNIT2,NDI)
C>    VOLUMETRIC CAUCHY STRESS 
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1
      DOUBLE PRECISION UNIT2(NDI,NDI),SVOL(NDI,NDI)
      DOUBLE PRECISION PV
C
      DO I1=1,NDI
        DO J1=1,NDI
          SVOL(I1,J1)=PV*UNIT2(I1,J1)
        END DO
      END DO
C
      RETURN
      END SUBROUTINE SIGVOL
      SUBROUTINE ISOMAT(SSEISO,DISO,C10,C01,CBARI1,CBARI2)
C>     ISOTROPIC MATRIX : ISOCHORIC SEF AND DERIVATIVES
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      DOUBLE PRECISION SSEISO,DISO(5)
      DOUBLE PRECISION C10,C01,CBARI1,CBARI2
C
      SSEISO=C10*(CBARI1-THREE)+C01*(CBARI2-THREE)
C
      !FIRST DERIVATIVE OF SSEISO IN ORDER TO I1
      DISO(1)=C10
      !FIRST DERIVATIVE OF SSEISO IN ORDER TO I2
      DISO(2)=C01
      !SECOND DERIVATIVE OF SSEISO IN ORDER TO I1
      DISO(3)=ZERO
      !SECOND DERIVATIVE OF SSEISO IN ORDER TO I2
      DISO(4)=ZERO
      !SECOND DERIVATIVE OF SSEISO IN ORDER TO I1 AND I2
      DISO(5)=ZERO
C
      RETURN
      END SUBROUTINE ISOMAT
      SUBROUTINE SDVREAD(STATEV,VV)
C>    VISCOUS DISSIPATION: READ STATE VARS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER VV
      DOUBLE PRECISION STATEV(NSDV)
C        read your sdvs here. they should be allocated. 
C          after the viscous terms (only if you use viscosity check hvread)
!        POS1=9*VV
!        DO I1=1,NCH
!         POS2=POS1+I1
!         FRAC(I1)=STATEV(POS2)
!        ENDDO
C
      RETURN
C
      END SUBROUTINE SDVREAD
      SUBROUTINE ANISOMAT(SSEANISO,DANISO,DISO,K1,K2,KDISP,I4,I1)
C>     ANISOTROPIC PART : ISOCHORIC SEF AND DERIVATIVES
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      DOUBLE PRECISION SSEISO,DANISO(4),DISO(5)
      DOUBLE PRECISION K1,K2,KDISP,I4,I1
      DOUBLE PRECISION DUDI1,D2UD2I1,SSEANISO
      DOUBLE PRECISION E1,EE2,EE3,DUDI4,D2UD2I4,D2DUDI1DI4,D2DUDI2DI4
C
      DUDI1=DISO(1)
      D2UD2I1=DISO(3)
C      
      E1=I4*(ONE-THREE*KDISP)+I1*KDISP-ONE
C
      SSEANISO=(K1/K2)*(DEXP(K1*E1*E1)-ONE)

      IF(E1.GT.ZERO) THEN
C
      EE2=DEXP(K2*E1*E1)
      EE3=(ONE+TWO*K2*E1*E1)
C
      DUDI1=DUDI1+K1*KDISP*E1*EE2
      D2UD2I1=D2UD2I1+K1*KDISP*KDISP*EE3*EE2
C      
      DUDI4=K1*(ONE-THREE*KDISP)*E1*EE2
C
      D2UD2I4=K1*((ONE-THREE*KDISP)**TWO)*EE3*EE2
      
      D2DUDI1DI4=K1*(ONE-THREE*KDISP)*KDISP*EE3*EE2
      D2DUDI2DI4=ZERO


C
      ELSE
      DUDI4=ZERO
      D2UD2I4=ZERO
      D2DUDI1DI4=ZERO
      D2DUDI2DI4=ZERO

      D2UD2I1=ZERO
C
      END IF
      !FIRST DERIVATIVE OF SSEANISO IN ORDER TO I1
      DANISO(1)=DUDI4
      !FIRST DERIVATIVE OF SSEANISO IN ORDER TO I2
      DANISO(2)=D2UD2I4
      !2ND DERIVATIVE OF SSEANISO IN ORDER TO I1
      DANISO(3)=D2DUDI1DI4
      !2ND DERIVATIVE OF SSEANISO IN ORDER TO I2
      DANISO(4)=D2DUDI2DI4
C
      DISO(1)=DUDI1
      DISO(3)=D2UD2I1
C
      RETURN
      END SUBROUTINE ANISOMAT
      SUBROUTINE PK2VOL(PKVOL,PV,C,NDI)
C>    VOLUMETRIC PK2 STRESS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1
      DOUBLE PRECISION PKVOL(NDI,NDI),C(NDI,NDI),CINV(NDI,NDI)
      DOUBLE PRECISION PV
C
      CALL MATINV3D(C,CINV,NDI)
C
      DO I1=1,NDI
        DO J1=1,NDI
          PKVOL(I1,J1)=PV*CINV(I1,J1)
        END DO
      END DO
C
      RETURN
      END SUBROUTINE PK2VOL
      SUBROUTINE PULL4(MAT,SPATIAL,FINV,DET,NDI)
C>        PULL-BACK TIMES DET OF 4TH ORDER TENSOR
       IMPLICIT NONE
       INCLUDE 'PARAM_UMAT.INC'
C
       INTEGER I1,J1,K1,L1,II1,JJ1,KK1,LL1,NDI
       DOUBLE PRECISION MAT(NDI,NDI,NDI,NDI),FINV(NDI,NDI)
       DOUBLE PRECISION SPATIAL(NDI,NDI,NDI,NDI)
       DOUBLE PRECISION AUX,DET
C
       DO I1=1,NDI
        DO J1=1,NDI
         DO K1=1,NDI
          DO L1=1,NDI
           AUX=ZERO
           DO II1=1,NDI
            DO JJ1=1,NDI
             DO KK1=1,NDI
              DO LL1=1,NDI
              AUX=AUX+DET*
     +        FINV(I1,II1)*FINV(J1,JJ1)*
     +        FINV(K1,KK1)*FINV(L1,LL1)*SPATIAL(II1,JJ1,KK1,LL1)
              END DO
             END DO
            END DO
           END DO
           MAT(I1,J1,K1,L1)=AUX
          END DO
         END DO
        END DO
       END DO
C
       RETURN
      END SUBROUTINE PULL4
      SUBROUTINE SETJR(CJR,SIGMA,UNIT2,NDI)
C>    JAUMAN RATE CONTRIBUTION FOR THE SPATIAL ELASTICITY TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1,K1,L1
      DOUBLE PRECISION UNIT2(NDI,NDI),
     1                 CJR(NDI,NDI,NDI,NDI),SIGMA(NDI,NDI)
C
      DO I1 = 1, NDI
        DO J1 = 1, NDI
         DO K1 = 1, NDI
           DO L1 = 1, NDI
              CJR(I1,J1,K1,L1)=
     1             (ONE/TWO)*(UNIT2(I1,K1)*SIGMA(J1,L1)
     2             +SIGMA(I1,K1)*UNIT2(J1,L1)+UNIT2(I1,L1)*SIGMA(J1,K1)
     3             +SIGMA(I1,L1)*UNIT2(J1,K1))
           END DO
         END DO
        END DO
      END DO
C
      RETURN
      END SUBROUTINE SETJR
      SUBROUTINE CONTRACTION44(S,LT,RT,NDI)
C>       DOUBLE CONTRACTION BETWEEN 4TH ORDER TENSORS
C>      INPUT:
C>       LT - RIGHT 4TH ORDER TENSOR
C>       RT - LEFT  4TH ORDER TENSOR
C>      OUTPUT:
C>       S - DOUBLE CONTRACTED TENSOR (4TH ORDER)
       IMPLICIT NONE
       INCLUDE 'PARAM_UMAT.INC'
C
       INTEGER I1,J1,K1,L1,M1,N1,NDI
C
       DOUBLE PRECISION LT(NDI,NDI,NDI,NDI),RT(NDI,NDI,NDI,NDI)
       DOUBLE PRECISION S(NDI,NDI,NDI,NDI)
       DOUBLE PRECISION AUX
C                     
       DO I1=1,NDI
        DO J1=1,NDI
         DO K1=1,NDI
          DO L1=1,NDI
           AUX=ZERO
           DO M1=1,NDI
            DO N1=1,NDI
                AUX=AUX+LT(I1,J1,M1,N1)*RT(M1,N1,K1,L1)
            END DO
           END DO
           S(I1,J1,K1,L1)=AUX
          END DO
         END DO
        END DO
       END DO
C
       RETURN
      END SUBROUTINE CONTRACTION44
       SUBROUTINE INITIALIZE(STATEV,VV)
C
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C      
C      COMMON /KCOMMON/KBLOCK
C
C      DOUBLE PRECISION TIME(2),KSTEP
      INTEGER I1,POS,POS1,POS2,POS3,VV
      DOUBLE PRECISION STATEV(NSDV)
C        VISCOUS TENSORS
       DO I1=1,VV
        POS=9*I1-9
        STATEV(1+POS)=ZERO
        STATEV(2+POS)=ZERO
        STATEV(3+POS)=ZERO
        STATEV(4+POS)=ZERO
        STATEV(5+POS)=ZERO
        STATEV(6+POS)=ZERO
        STATEV(7+POS)=ZERO
        STATEV(8+POS)=ZERO
        STATEV(9+POS)=ZERO
       ENDDO
       POS1=9*VV
C        DETERMINANT
        STATEV(POS1+1)=ONE
C     
      RETURN
C
      END SUBROUTINE INITIALIZE
      SUBROUTINE SETVOL(CVOL,PV,PPV,UNIT2,UNIT4S,NDI)
C>    VOLUMETRIC SPATIAL ELASTICITY TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1,K1,L1
      DOUBLE PRECISION UNIT2(NDI,NDI),UNIT4S(NDI,NDI,NDI,NDI),
     1                 CVOL(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION PV,PPV
C
      DO I1 = 1, NDI
        DO J1 = 1, NDI
         DO K1 = 1, NDI
           DO L1 = 1, NDI
             CVOL(I1,J1,K1,L1)=
     1                 PPV*UNIT2(I1,J1)*UNIT2(K1,L1)
     2                 -TWO*PV*UNIT4S(I1,J1,K1,L1)
           END DO
         END DO
        END DO
      END DO
C      
      RETURN
      END SUBROUTINE SETVOL
      SUBROUTINE HVWRITE(STATEV,HV,V1,NDI)
C>    VISCOUS DISSIPATION: WRITE STATE VARS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,V1,POS
      DOUBLE PRECISION HV(NDI,NDI),STATEV(NSDV)
C
        POS=9*V1-9
        STATEV(1+POS)=HV(1,1)
        STATEV(2+POS)=HV(1,2)
        STATEV(3+POS)=HV(1,3)
        STATEV(4+POS)=HV(2,1)
        STATEV(5+POS)=HV(2,2)
        STATEV(6+POS)=HV(2,3)
        STATEV(7+POS)=HV(3,1)
        STATEV(8+POS)=HV(3,2)
        STATEV(9+POS)=HV(3,3)
C
      RETURN
C      
      END SUBROUTINE HVWRITE
      SUBROUTINE PK2ISOMATFIC(FIC,DISO,CBAR,CBARI1,UNIT2,NDI)
C>     ISOTROPIC MATRIX: 2PK 'FICTICIOUS' STRESS TENSOR
C      INPUT:
C       DISO - STRAIN-ENERGY DERIVATIVES
C       CBAR - DEVIATORIC LEFT CAUCHY-GREEN TENSOR
C       CBARI1,CBARI2 - CBAR INVARIANTS
C       UNIT2 - 2ND ORDER IDENTITY TENSOR
C      OUTPUT:
C       FIC - 2ND PIOLA KIRCHOOF 'FICTICIOUS' STRESS TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER I1,J1,NDI
      DOUBLE PRECISION FIC(NDI,NDI),DISO(5),CBAR(NDI,NDI),UNIT2(NDI,NDI)
      DOUBLE PRECISION DUDI1,DUDI2,CBARI1
      DOUBLE PRECISION AUX1,AUX2    
C
      DUDI1=DISO(1)
      DUDI2=DISO(2)
C
      AUX1=TWO*(DUDI1+CBARI1*DUDI2)
      AUX2=-TWO*DUDI2
C
      DO I1=1,NDI
       DO J1=1,NDI
        FIC(I1,J1)=AUX1*UNIT2(I1,J1)+AUX2*CBAR(I1,J1)
       END DO
      END DO
C
      RETURN
      END SUBROUTINE PK2ISOMATFIC
      SUBROUTINE SIGISOMATFIC(SFIC,PKFIC,F,DET,NDI)
C>    ISOTROPIC MATRIX:  ISOCHORIC CAUCHY STRESS 
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI
      DOUBLE PRECISION SFIC(NDI,NDI),F(NDI,NDI),
     1                 PKFIC(NDI,NDI)
      DOUBLE PRECISION DET
C
      CALL PUSH2(SFIC,PKFIC,F,DET,NDI)
C
      RETURN
      END SUBROUTINE SIGISOMATFIC
      SUBROUTINE PK2ANISOMATFIC(AFIC,DANISO,CBAR,INV4,ST0,NDI)
C>      ANISOTROPIC MATRIX: 2PK 'FICTICIOUS' STRESS TENSOR
C       INPUT:
C       DANISO - ANISOTROPIC STRAIN-ENERGY DERIVATIVES
C       CBAR - DEVIATORIC LEFT CAUCHY-GREEN TENSOR
C       INV1,INV4 -CBAR INVARIANTS
C       UNIT2 - 2ND ORDER IDENTITY TENSOR
C       OUTPUT:
C       AFIC - 2ND PIOLA KIRCHOOF 'FICTICIOUS' STRESS TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI
      DOUBLE PRECISION AFIC(NDI,NDI),DANISO(3),CBAR(3,3)
      DOUBLE PRECISION DUDI4,DI4DC(3,3),INV4
      DOUBLE PRECISION ST0(3,3)
C
C
C-----------------------------------------------------------------------------
      !FIRST DERIVATIVE OF SSEANISO IN ORDER TO I4
      DUDI4=DANISO(1)
C
      DI4DC=ST0
C
      AFIC=TWO*(DUDI4*DI4DC)
C
      RETURN
      END SUBROUTINE PK2ANISOMATFIC
      SUBROUTINE STRETCH(C,B,U,V,NDI)
C>    STRETCH TENSORS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI
      DOUBLE PRECISION C(NDI,NDI),B(NDI,NDI),U(NDI,NDI),V(NDI,NDI)
      DOUBLE PRECISION EIGVAL(NDI),OMEGA(NDI),EIGVEC(NDI,NDI)
C
      CALL SPECTRAL(C,OMEGA,EIGVEC)
C
      EIGVAL(1) = DSQRT(OMEGA(1))
      EIGVAL(2) = DSQRT(OMEGA(2))
      EIGVAL(3) = DSQRT(OMEGA(3))
C
      U(1,1) = EIGVAL(1)
      U(2,2) = EIGVAL(2)
      U(3,3) = EIGVAL(3)
C
      U = MATMUL(MATMUL(EIGVEC,U),TRANSPOSE(EIGVEC))
C
      CALL SPECTRAL(B,OMEGA,EIGVEC)
C
      EIGVAL(1) = DSQRT(OMEGA(1))
      EIGVAL(2) = DSQRT(OMEGA(2))
      EIGVAL(3) = DSQRT(OMEGA(3))      
C      write(*,*) eigvec(1,1),eigvec(2,1),eigvec(3,1)
C
      V(1,1) = EIGVAL(1)
      V(2,2) = EIGVAL(2)
      V(3,3) = EIGVAL(3)
C
      V = MATMUL(MATMUL(EIGVEC,V),TRANSPOSE(EIGVEC))
      RETURN
      END SUBROUTINE STRETCH
      SUBROUTINE MATINV3D(A,A_INV,NDI)
C>    INVERSE OF A 3X3 MATRIX
C     RETURN THE INVERSE OF A(3,3) - A_INV
      IMPLICIT NONE
C
      INTEGER NDI
C
      DOUBLE PRECISION A(NDI,NDI),A_INV(NDI,NDI),DET_A,DET_A_INV
C
      DET_A = A(1,1)*(A(2,2)*A(3,3) - A(3,2)*A(2,3)) -
     +        A(2,1)*(A(1,2)*A(3,3) - A(3,2)*A(1,3)) +
     +        A(3,1)*(A(1,2)*A(2,3) - A(2,2)*A(1,3))

      IF (DET_A .LE. 0.D0) THEN
        WRITE(*,*) 'WARNING: SUBROUTINE MATINV3D:'
        WRITE(*,*) 'WARNING: DET OF MAT=',DET_A
        RETURN
      END IF
C
      DET_A_INV = 1.D0/DET_A
C
      A_INV(1,1) = DET_A_INV*(A(2,2)*A(3,3)-A(3,2)*A(2,3))
      A_INV(1,2) = DET_A_INV*(A(3,2)*A(1,3)-A(1,2)*A(3,3))
      A_INV(1,3) = DET_A_INV*(A(1,2)*A(2,3)-A(2,2)*A(1,3))
      A_INV(2,1) = DET_A_INV*(A(3,1)*A(2,3)-A(2,1)*A(3,3))
      A_INV(2,2) = DET_A_INV*(A(1,1)*A(3,3)-A(3,1)*A(1,3))
      A_INV(2,3) = DET_A_INV*(A(2,1)*A(1,3)-A(1,1)*A(2,3))
      A_INV(3,1) = DET_A_INV*(A(2,1)*A(3,2)-A(3,1)*A(2,2))
      A_INV(3,2) = DET_A_INV*(A(3,1)*A(1,2)-A(1,1)*A(3,2))
      A_INV(3,3) = DET_A_INV*(A(1,1)*A(2,2)-A(2,1)*A(1,2))
C
      RETURN
      END SUBROUTINE MATINV3D
      SUBROUTINE SPECTRAL(A,D,V)
C>    EIGENVALUES AND EIGENVECTOR OF A 3X3 MATRIX
C     THIS SUBROUTINE CALCULATES THE EIGENVALUES AND EIGENVECTORS OF
C     A SYMMETRIC 3X3 MATRIX A.
C
C     THE OUTPUT CONSISTS OF A VECTOR D CONTAINING THE THREE
C     EIGENVALUES IN ASCENDING ORDER, AND A MATRIX V WHOSE
C     COLUMNS CONTAIN THE CORRESPONDING EIGENVECTORS.
C
      IMPLICIT NONE
C
      INTEGER NP,NROT
      PARAMETER(NP=3)
C
      DOUBLE PRECISION D(3),V(3,3),A(3,3),E(3,3)
C
      E = A
C
      CALL JACOBI(E,3,NP,D,V,NROT)
      CALL EIGSRT(D,V,3,NP)
C
      RETURN
      END SUBROUTINE SPECTRAL

C***********************************************************************

      SUBROUTINE JACOBI(A,N,NP,D,V,NROT)
C
C COMPUTES ALL EIGENVALUES AND EIGENVECTORS OF A REAL SYMMETRIC
C  MATRIX A, WHICH IS OF SIZE N BY N, STORED IN A PHYSICAL
C  NP BY NP ARRAY.  ON OUTPUT, ELEMENTS OF A ABOVE THE DIAGONAL
C  ARE DESTROYED, BUT THE DIAGONAL AND SUB-DIAGONAL ARE UNCHANGED
C  AND GIVE FULL INFORMATION ABOUT THE ORIGINAL SYMMETRIC MATRIX.
C  VECTOR D RETURNS THE EIGENVALUES OF A IN ITS FIRST N ELEMENTS.
C  V IS A MATRIX WITH THE SAME LOGICAL AND PHYSICAL DIMENSIONS AS
C  A WHOSE COLUMNS CONTAIN, UPON OUTPUT, THE NORMALIZED
C  EIGENVECTORS OF A.  NROT RETURNS THE NUMBER OF JACOBI ROTATION
C  WHICH WERE REQUIRED.
C
C THIS SUBROUTINE IS TAKEN FROM 'NUMERICAL RECIPES.'
C
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER IP,IQ,N,NMAX,NP,NROT,I,J
      PARAMETER (NMAX=100)
C
      DOUBLE PRECISION A(NP,NP),D(NP),V(NP,NP),B(NMAX),Z(NMAX),
     +  SM,TRESH,G,T,H,THETA,S,C,TAU


C INITIALIZE V TO THE IDENTITY MATRIX
      DO I=1,3
          V(I,I)=ONE
        DO J=1,3
          IF (I.NE.J)THEN
           V(I,J)=ZERO
         ENDIF
       END DO
      END DO
C INITIALIZE B AND D TO THE DIAGONAL OF A, AND Z TO ZERO.
C  THE VECTOR Z WILL ACCUMULATE TERMS OF THE FORM T*A_PQ AS
C  IN EQUATION (11.1.14)
C
      DO IP = 1,N
        B(IP) = A(IP,IP)
        D(IP) = B(IP)
        Z(IP) = 0.D0
      END DO


C BEGIN ITERATION
C
      NROT = 0
      DO I=1,50
C
C         SUM OFF-DIAGONAL ELEMENTS
C
          SM = 0.D0
          DO IP=1,N-1
            DO IQ=IP+1,N
              SM = SM + DABS(A(IP,IQ))
            END DO
          END DO
C
C          IF SM = 0., THEN RETURN.  THIS IS THE NORMAL RETURN,
C          WHICH RELIES ON QUADRATIC CONVERGENCE TO MACHINE
C          UNDERFLOW.
C
          IF (SM.EQ.0.D0) RETURN
C
C          IN THE FIRST THREE SWEEPS CARRY OUT THE PQ ROTATION ONLY IF
C           |A_PQ| > TRESH, WHERE TRESH IS SOME THRESHOLD VALUE,
C           SEE EQUATION (11.1.25).  THEREAFTER TRESH = 0.
C
          IF (I.LT.4) THEN
            TRESH = 0.2D0*SM/N**2
          ELSE
            TRESH = 0.D0
          END IF
C
          DO IP=1,N-1
            DO IQ=IP+1,N
              G = 100.D0*DABS(A(IP,IQ))
C
C              AFTER FOUR SWEEPS, SKIP THE ROTATION IF THE
C               OFF-DIAGONAL ELEMENT IS SMALL.
C
              IF ((I.GT.4).AND.(DABS(D(IP))+G.EQ.DABS(D(IP)))
     +            .AND.(DABS(D(IQ))+G.EQ.DABS(D(IQ)))) THEN
                A(IP,IQ) = 0.D0
              ELSE IF (DABS(A(IP,IQ)).GT.TRESH) THEN
                H = D(IQ) - D(IP)
                IF (DABS(H)+G.EQ.DABS(H)) THEN
C
C                  T = 1./(2.*THETA), EQUATION (11.1.10)
C
                  T =A(IP,IQ)/H
                ELSE
                  THETA = 0.5D0*H/A(IP,IQ)
                  T =1.D0/(DABS(THETA)+DSQRT(1.D0+THETA**2.D0))
                  IF (THETA.LT.0.D0) T = -T
                END IF
                C = 1.D0/DSQRT(1.D0 + T**2.D0)
                S = T*C
                TAU = S/(1.D0 + C)
                H = T*A(IP,IQ)
                Z(IP) = Z(IP) - H
                Z(IQ) = Z(IQ) + H
                D(IP) = D(IP) - H
                D(IQ) = D(IQ) + H
                A(IP,IQ) = 0.D0
C
C               CASE OF ROTATIONS 1 <= J < P
C
                DO J=1,IP-1
                  G = A(J,IP)
                  H = A(J,IQ)
                  A(J,IP) = G - S*(H + G*TAU)
                  A(J,IQ) = H + S*(G - H*TAU)
                END DO
C
C                CASE OF ROTATIONS P < J < Q
C
                DO J=IP+1,IQ-1
                  G = A(IP,J)
                  H = A(J,IQ)
                  A(IP,J) = G - S*(H + G*TAU)
                  A(J,IQ) = H + S*(G - H*TAU)
                END DO
C
C                 CASE OF ROTATIONS Q < J <= N
C
                DO J=IQ+1,N
                  G = A(IP,J)
                  H = A(IQ,J)
                  A(IP,J) = G - S*(H + G*TAU)
                  A(IQ,J) = H + S*(G - H*TAU)
                END DO
                DO J = 1,N
                  G = V(J,IP)
                  H = V(J,IQ)
                  V(J,IP) = G - S*(H + G*TAU)
                  V(J,IQ) = H + S*(G - H*TAU)
                END DO
                NROT = NROT + 1
             END IF
               END DO
             END DO
C
C          UPDATE D WITH THE SUM OF T*A_PQ, AND REINITIALIZE Z
C
       DO IP=1,N
         B(IP) = B(IP) + Z(IP)
         D(IP) = B(IP)
         Z(IP) = 0.D0
       END DO
      END DO
C
C IF THE ALGORITHM HAS REACHED THIS STAGE, THEN THERE
C  ARE TOO MANY SWEEPS.  PRINT A DIAGNOSTIC AND CUT THE
C  TIME INCREMENT.
C
      WRITE (*,'(/1X,A/)') '50 ITERATIONS IN JACOBI SHOULD NEVER HAPPEN'
C
      RETURN
      END SUBROUTINE JACOBI

C**********************************************************************
      SUBROUTINE EIGSRT(D,V,N,NP)
C
C     GIVEN THE EIGENVALUES D AND EIGENVECTORS V AS OUTPUT FROM
C     JACOBI, THIS SUBROUTINE SORTS THE EIGENVALUES INTO ASCENDING
C     ORDER AND REARRANGES THE COLMNS OF V ACCORDINGLY.
C
C     THE SUBROUTINE WAS TAKEN FROM 'NUMERICAL RECIPES.'
C
      IMPLICIT NONE
C
      INTEGER N,NP,I,J,K
C
      DOUBLE PRECISION D(NP),V(NP,NP),P
C
      DO I=1,N-1
              K = I
              P = D(I)
              DO J=I+1,N
               IF (D(J).GE.P) THEN
                K = J
                P = D(J)
               END IF
              END DO
              IF (K.NE.I) THEN
               D(K) = D(I)
               D(I) = P
               DO J=1,N
                P = V(J,I)
                V(J,I) = V(J,K)
                V(J,K) = P
               END DO
              END IF
      END DO
C
      RETURN
      END SUBROUTINE EIGSRT
       SUBROUTINE TENSORPROD2(A,B,C,NDI)
C
       Implicit None
C
       INTEGER I,J,K,L,NDI
C
       DOUBLE PRECISION A(NDI,NDI),B(NDI,NDI),C(NDI,NDI,NDI,NDI)
C
      DO I=1,NDI
       DO J=1,NDI
         DO K=1,NDI
          DO L=1,NDI
          C(I,J,K,L)=A(I,J)*B(K,L)
          END DO
         END DO
       END DO
      END DO
C
      RETURN
C
      end SUBROUTINE TENSORPROD2
      SUBROUTINE CONTRACTION24(S,LT,RT,NDI)
C>       DOUBLE CONTRACTION BETWEEN 4TH ORDER AND 2ND ORDER  TENSOR
C>      INPUT:
C>       LT - RIGHT 2ND ORDER TENSOR
C>       RT - LEFT  4TH ODER TENSOR
C>      OUTPUT:
C>       S - DOUBLE CONTRACTED TENSOR (2ND ORDER)
       IMPLICIT NONE
       INCLUDE 'PARAM_UMAT.INC'
C
       INTEGER I1,J1,K1,L1,NDI
C
       DOUBLE PRECISION LT(NDI,NDI),RT(NDI,NDI,NDI,NDI)
       DOUBLE PRECISION S(NDI,NDI)
       DOUBLE PRECISION AUX
C
      DO K1=1,NDI
       DO L1=1,NDI
         AUX=ZERO
        DO I1=1,NDI
         DO J1=1,NDI
           AUX=AUX+LT(K1,L1)*RT(I1,J1,K1,L1)
        END DO
       END DO
          S(K1,L1)=AUX
      END DO
      END DO
       RETURN
      END SUBROUTINE CONTRACTION24
      SUBROUTINE INVARIANTS(A,INV1,INV2,NDI)
C>    1ST AND 2ND INVARIANTS OF A TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1
      DOUBLE PRECISION A(NDI,NDI),AA(NDI,NDI)
      DOUBLE PRECISION INV1,INV1AA, INV2
C
      INV1=ZERO
      INV1AA=ZERO
      AA=MATMUL(A,A)
      DO I1=1,NDI
         INV1=INV1+A(I1,I1)
         INV1AA=INV1AA+AA(I1,I1)
      END DO
         INV2=(ONE/TWO)*(INV1*INV1-INV1AA)
C
      RETURN
      END SUBROUTINE INVARIANTS
      SUBROUTINE SIGISO(SISO,SFIC,PE,NDI)
C>    ISOCHORIC CAUCHY STRESS 
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI
      DOUBLE PRECISION SISO(NDI,NDI),
     1                 PE(NDI,NDI,NDI,NDI),SFIC(NDI,NDI)
C
      CALL CONTRACTION42(SISO,PE,SFIC,NDI)
C
      RETURN
      END SUBROUTINE SIGISO
      SUBROUTINE VOL(SSEV,PV,PPV,K,DET)
C>     VOLUMETRIC CONTRIBUTION :STRAIN ENERGY FUNCTION AND DERIVATIVES
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      DOUBLE PRECISION SSEV,PV,PPV
      DOUBLE PRECISION K,G,DET,AUX
C
      G=(ONE/FOUR)*(DET*DET-ONE-TWO*LOG(DET))
C
      SSEV=K*G
C
      PV=K*(ONE/TWO)*(DET-ONE/DET)
      AUX=K*(ONE/TWO)*(ONE+ONE/(DET*DET))
      PPV=PV+DET*AUX
C
      RETURN
      END SUBROUTINE VOL
      SUBROUTINE PUSH4(SPATIAL,MAT,F,DET,NDI)
C>        PIOLA TRANSFORMATION
C>      INPUT:
C>       MAT - MATERIAL ELASTICITY TENSOR
C>       F - DEFORMATION GRADIENT
C>       DET - DEFORMATION DETERMINANT
C>      OUTPUT:
C>       SPATIAL - SPATIAL ELASTICITY TENSOR
       IMPLICIT NONE
       INCLUDE 'PARAM_UMAT.INC'
C
       INTEGER I1,J1,K1,L1,II1,JJ1,KK1,LL1,NDI
C
       DOUBLE PRECISION MAT(NDI,NDI,NDI,NDI),F(NDI,NDI)
       DOUBLE PRECISION SPATIAL(NDI,NDI,NDI,NDI)
       DOUBLE PRECISION AUX,DET
C
       DO I1=1,NDI
        DO J1=1,NDI
         DO K1=1,NDI
          DO L1=1,NDI
           AUX=ZERO
           DO II1=1,NDI
            DO JJ1=1,NDI
             DO KK1=1,NDI
              DO LL1=1,NDI
              AUX=AUX+(DET**(-ONE))*
     +        F(I1,II1)*F(J1,JJ1)*
     +        F(K1,KK1)*F(L1,LL1)*MAT(II1,JJ1,KK1,LL1)
              END DO
             END DO
            END DO
           END DO
           SPATIAL(I1,J1,K1,L1)=AUX
          END DO
         END DO
        END DO
       END DO
C
       RETURN
      END SUBROUTINE PUSH4
      SUBROUTINE PK2ISO(PKISO,PKFIC,PL,DET,NDI)
C>    ISOCHORIC PK2 STRESS TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1
      DOUBLE PRECISION PKISO(NDI,NDI),
     1                 PL(NDI,NDI,NDI,NDI),PKFIC(NDI,NDI)
      DOUBLE PRECISION DET,SCALE2      
C
      CALL CONTRACTION42(PKISO,PL,PKFIC,NDI)
C
      SCALE2=DET**(-TWO/THREE)
      DO I1=1,NDI
        DO J1=1,NDI
          PKISO(I1,J1)=SCALE2*PKISO(I1,J1)
        END DO
      END DO
C
      RETURN
      END SUBROUTINE PK2ISO
      SUBROUTINE ONEM(A,AA,AAS,NDI)
C
C>      THIS SUBROUTINE GIVES:
C>          2ND ORDER IDENTITY TENSORS - A
C>          4TH ORDER IDENTITY TENSOR - AA
C>          4TH ORDER SYMMETRIC IDENTITY TENSOR - AAS
C
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER I,J,K,L,NDI
C
      DOUBLE PRECISION A(NDI,NDI),AA(NDI,NDI,NDI,NDI),
     1                 AAS(NDI,NDI,NDI,NDI)
C
      DO I=1,NDI
         DO J=1,NDI
            IF (I .EQ. J) THEN
              A(I,J) = ONE
            ELSE
              A(I,J) = ZERO
            END IF
         END DO
      END DO
C
      DO I=1,NDI
         DO J=1,NDI
          DO K=1,NDI
             DO L=1,NDI
              AA(I,J,K,L)=A(I,K)*A(J,L)
              AAS(I,J,K,L)=(ONE/TWO)*(A(I,K)*A(J,L)+A(I,L)*A(J,K))
           END DO
          END DO
        END DO
      END DO
C
      RETURN
      END SUBROUTINE ONEM
      SUBROUTINE METISO(CMISO,CMFIC,PL,PKISO,PKFIC,C,UNIT2,DET,NDI)
C>    ISOCHORIC MATERIAL ELASTICITY TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1,K1,L1
      DOUBLE PRECISION UNIT2(NDI,NDI),PL(NDI,NDI,NDI,NDI),
     1                 CMISO(NDI,NDI,NDI,NDI),PKISO(NDI,NDI),
     2                 CMFIC(NDI,NDI,NDI,NDI),PKFIC(NDI,NDI),
     3                 CISOAUX(NDI,NDI,NDI,NDI),
     4                 CISOAUX1(NDI,NDI,NDI,NDI),C(NDI,NDI),
     5                 PLT(NDI,NDI,NDI,NDI),CINV(NDI,NDI),
     6                 PLL(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION TRFIC,XX,YY,ZZ,DET,AUX,AUX1
C
      CALL MATINV3D(C,CINV,NDI)
      CISOAUX1=ZERO
      CISOAUX=ZERO
      CALL CONTRACTION44(CISOAUX1,PL,CMFIC,NDI)
C      
C  transpose of lagrangian projection tensor     
      DO I1=1,NDI
        DO J1=1,NDI
           DO K1=1,NDI
              DO L1=1,NDI
                PLT(I1,J1,K1,L1)=PL(K1,L1,I1,J1)
              END DO
            END DO
         END DO
      END DO
C
      CALL CONTRACTION44(CISOAUX,CISOAUX1,PLT,NDI)
C
      TRFIC=ZERO
      AUX=DET**(-TWO/THREE)
      AUX1=AUX**TWO
      DO I1=1,NDI
         TRFIC=TRFIC+AUX*PKFIC(I1,I1)*C(I1,I1)
      END DO
C
      DO I1=1,NDI
        DO J1=1,NDI
           DO K1=1,NDI
              DO L1=1,NDI
                XX=AUX1*CISOAUX(I1,J1,K1,L1)
                PLL(I1,J1,K1,L1)=(ONE/TWO)*(CINV(I1,K1)*CINV(J1,L1)+
     1                                      CINV(I1,L1)*CINV(J1,K1))-
     2                           (ONE/THREE)*CINV(I1,J1)*CINV(K1,L1)
                YY=TRFIC*PLL(I1,J1,K1,L1)
                ZZ=PKISO(I1,J1)*CINV(K1,L1)+CINV(I1,J1)*PKISO(K1,L1)
C
                CMISO(I1,J1,K1,L1)=XX+(TWO/THREE)*YY-(TWO/THREE)*ZZ
              END DO
           END DO
        END DO
      END DO
C
      RETURN
      END SUBROUTINE METISO
      SUBROUTINE SETISO(CISO,CFIC,PE,SISO,SFIC,UNIT2,NDI)
C>    ISOCHORIC SPATIAL ELASTICITY TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1,K1,L1
      DOUBLE PRECISION UNIT2(NDI,NDI),PE(NDI,NDI,NDI,NDI),
     1                 CISO(NDI,NDI,NDI,NDI),SISO(NDI,NDI),
     2                 CFIC(NDI,NDI,NDI,NDI),SFIC(NDI,NDI),
     3                 CISOAUX(NDI,NDI,NDI,NDI),
     4                 CISOAUX1(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION TRFIC,XX,YY,ZZ
C
      CISOAUX1=ZERO
      CISOAUX=ZERO

      CALL CONTRACTION44(CISOAUX1,PE,CFIC,NDI)      
      CALL CONTRACTION44(CISOAUX,CISOAUX1,PE,NDI)
C
      TRFIC=ZERO
      DO I1=1,NDI
         TRFIC=TRFIC+SFIC(I1,I1)
      END DO
C
      DO I1=1,NDI
        DO J1=1,NDI
           DO K1=1,NDI
              DO L1=1,NDI
                XX=CISOAUX(I1,J1,K1,L1)
                YY=TRFIC*PE(I1,J1,K1,L1)
                ZZ=SISO(I1,J1)*UNIT2(K1,L1)+UNIT2(I1,J1)*SISO(K1,L1)
C                
                CISO(I1,J1,K1,L1)=XX+(TWO/THREE)*YY-(TWO/THREE)*ZZ
              END DO
           END DO
        END DO
      END DO
C
      RETURN
      END SUBROUTINE SETISO
      SUBROUTINE PUSH2(SIG,PK,F,DET,NDI)
C>        PIOLA TRANSFORMATION
C>      INPUT:
C>       PK - 2ND PIOLA KIRCHOOF STRESS TENSOR
C>       F - DEFORMATION GRADIENT
C>       DET - DEFORMATION DETERMINANT
C>      OUTPUT:
C>       SIG - CAUCHY STRESS TENSOR
       IMPLICIT NONE
       INCLUDE 'PARAM_UMAT.INC'
C
       INTEGER I1,J1,II1,JJ1,NDI
       DOUBLE PRECISION PK(NDI,NDI),F(NDI,NDI)
       DOUBLE PRECISION SIG(NDI,NDI)
       DOUBLE PRECISION AUX,DET
C
       DO I1=1,NDI
        DO J1=1,NDI
          AUX=ZERO
         DO II1=1,NDI
          DO JJ1=1,NDI
            AUX=AUX+(DET**(-ONE))*F(I1,II1)*F(J1,JJ1)*PK(II1,JJ1)
         END DO
        END DO
           SIG(I1,J1)=AUX
        END DO
       END DO
C
       RETURN
      END SUBROUTINE PUSH2
      SUBROUTINE DEFORMATION(F,C,B,NDI)
C>     RIGHT AND LEFT CAUCHY-GREEN DEFORMATION TENSORS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI
      DOUBLE PRECISION F(NDI,NDI),C(NDI,NDI),B(NDI,NDI) 
C     RIGHT CAUCHY-GREEN DEFORMATION TENSOR
      C=MATMUL(TRANSPOSE(F),F)
C     LEFT CAUCHY-GREEN DEFORMATION TENSOR
      B=MATMUL(F,TRANSPOSE(F))
      RETURN
      END SUBROUTINE DEFORMATION
      SUBROUTINE FSLIP(F,FBAR,DET,NDI)
C>     DISTORTION GRADIENT
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1
      DOUBLE PRECISION F(NDI,NDI),FBAR(NDI,NDI)
      DOUBLE PRECISION DET,SCALE1
C     
C     JACOBIAN DETERMINANT
      DET = F(1,1) * F(2,2) * F(3,3)
     1    - F(1,2) * F(2,1) * F(3,3)
C
      IF (NDI .EQ. 3) THEN
          DET = DET + F(1,2) * F(2,3) * F(3,1)
     1              + F(1,3) * F(3,2) * F(2,1)
     2              - F(1,3) * F(3,1) * F(2,2)
     3              - F(2,3) * F(3,2) * F(1,1)
      END IF 
C
      SCALE1=DET**(-ONE /THREE)
C      
      DO I1=1,NDI
        DO J1=1,NDI
          FBAR(I1,J1)=SCALE1*F(I1,J1)
        END DO
      END DO
C
      RETURN      
      END SUBROUTINE FSLIP
      SUBROUTINE CMATANISOMATFIC(CMANISOMATFIC,M0,DANISO,UNIT2,DET,NDI)
C
C>    ANISOTROPIC MATRIX: MATERIAL 'FICTICIOUS' ELASTICITY TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I,J,K,L
      DOUBLE PRECISION CMANISOMATFIC(NDI,NDI,NDI,NDI),UNIT2(NDI,NDI),
     1                 M0(NDI,NDI),DANISO(3),DET
      DOUBLE PRECISION CINV4(NDI,NDI,NDI,NDI),CINV14(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION D2UDI4,D2UDI1DI4
      DOUBLE PRECISION IMM(NDI,NDI,NDI,NDI),MMI(NDI,NDI,NDI,NDI),
     1                 MM0(NDI,NDI,NDI,NDI)
C
C-----------------------------------------------------------------------------
      !2ND DERIVATIVE OF SSEANISO IN ORDER TO I4
      D2UDI4=DANISO(2)
      !2ND DERIVATIVE OF SSEANISO IN ORDER TO I1 AND I4
      D2UDI1DI4=DANISO(3)
C
      CALL TENSORPROD2(M0,M0,MM0,NDI)
      CALL TENSORPROD2(UNIT2,M0,IMM,NDI)
      CALL TENSORPROD2(M0,UNIT2,MMI,NDI)
C
      DO I=1,NDI
       DO J=1,NDI
         DO K=1,NDI
          DO L=1,NDI
          CINV4(I,J,K,L)=D2UDI4*MM0(I,J,K,L)
          CINV14(I,J,K,L)=D2UDI1DI4*(IMM(I,J,K,L)+MMI(I,J,K,L))
          CMANISOMATFIC(I,J,K,L)=FOUR*(CINV4(I,J,K,L)+CINV14(I,J,K,L))
          END DO
         END DO
       END DO
      END DO
C
      RETURN
      END SUBROUTINE CMATANISOMATFIC
      SUBROUTINE SDVWRITE(STATEV,DET,VV)
C>    VISCOUS DISSIPATION: WRITE STATE VARS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      DOUBLE PRECISION STATEV(NSDV),DET
      INTEGER VV,POS1
C        write your sdvs here. they should be allocated 
C                after the viscous terms (check hvwrite)
      POS1=9*VV 
      STATEV(POS1+1)=DET

      RETURN
C
      END SUBROUTINE SDVWRITE
      SUBROUTINE VISCO(PK,CMAT,VV,PKVOL,PKISO,CMATVOL,CMATISO,DTIME,
     1                                              VSCPROPS,STATEV,NDI)
C>    VISCOUS DISSIPATION: MAXWELL SPRINGS AND DASHPOTS SCHEME
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      DOUBLE PRECISION PK(NDI,NDI),PKVOL(NDI,NDI),PKISO(NDI,NDI),
     1                  CMAT(NDI,NDI,NDI,NDI),CMATVOL(NDI,NDI,NDI,NDI),
     2                  CMATISO(NDI,NDI,NDI,NDI),VSCPROPS(6)
      DOUBLE PRECISION Q(NDI,NDI),QV(NDI,NDI),HV(NDI,NDI),
     1                  HV0(NDI,NDI),STATEV(NSDV)
      DOUBLE PRECISION DTIME,TETA,TAU,AUX,AUXC
      INTEGER I1,J1,K1,L1,NDI,VV,V1
C      
      Q=ZERO
      QV=ZERO
      HV=ZERO
      AUXC=ZERO
C      
C     ( GENERAL MAXWELL DASHPOTS)
      DO V1=1,VV 
C      
      TAU=VSCPROPS(2*V1-1)
      TETA=VSCPROPS(2*V1)
C
C      READ STATE VARIABLES
      CALL HVREAD(HV,STATEV,V1,NDI)
      HV0=HV
C        RALAXATION TENSORS      
      CALL RELAX(QV,HV,AUX,HV0,PKISO,DTIME,TAU,TETA,NDI)
      AUXC=AUXC+AUX     
C        WRITE STATE VARIABLES      
      CALL HVWRITE(STATEV,HV,V1,NDI)
C
      Q=Q+QV
C
      END DO
C              
      AUXC=ONE+AUXC
      PK=PKVOL+PKISO
C 
      DO I1=1,NDI
       DO J1=1,NDI
        PK(I1,J1)=PK(I1,J1)+Q(I1,J1)
        DO K1=1,NDI
         DO L1=1,NDI
          CMAT(I1,J1,K1,L1)= CMATVOL(I1,J1,K1,L1)+
     1                        AUXC*CMATISO(I1,J1,K1,L1)
         ENDDO
        ENDDO
       ENDDO
      ENDDO
      
C
C
      RETURN
      END SUBROUTINE VISCO
      SUBROUTINE RESETDFGRD(DFGRD,NDI)
C
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
      
      INTEGER NDI
      DOUBLE PRECISION DFGRD(NDI,NDI)

        DFGRD(1,1)=  ONE
        DFGRD(1,2)=  ZERO
        DFGRD(1,3)=  ZERO
        DFGRD(2,1)=  ZERO
        DFGRD(2,2)=  ONE
        DFGRD(2,3)=  ZERO
        DFGRD(3,1)=  ZERO
        DFGRD(3,2)=  ZERO
        DFGRD(3,3)=  ONE

      END SUBROUTINE RESETDFGRD
      SUBROUTINE INDEXX(STRESS,DDSDDE,SIG,TNG,NTENS,NDI)
C>    INDEXATION: FULL SIMMETRY  IN STRESSES AND ELASTICITY TENSORS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER II1(6),II2(6),NTENS,NDI,I1,J1
      DOUBLE PRECISION STRESS(NTENS),DDSDDE(NTENS,NTENS)
      DOUBLE PRECISION SIG(NDI,NDI),TNG(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION PP1,PP2
C
      II1(1)=1
      II1(2)=2
      II1(3)=3
      II1(4)=1
      II1(5)=1
      II1(6)=2
C
      II2(1)=1
      II2(2)=2
      II2(3)=3
      II2(4)=2
      II2(5)=3
      II2(6)=3
C
      DO I1=1,NTENS
C       STRESS VECTOR
         STRESS(I1)=SIG(II1(I1),II2(I1))
         DO J1=1,NTENS
C       DDSDDE - FULLY SIMMETRY IMPOSED
            PP1=TNG(II1(I1),II2(I1),II1(J1),II2(J1))
            PP2=TNG(II1(I1),II2(I1),II2(J1),II1(J1))
            DDSDDE(I1,J1)=(ONE/TWO)*(PP1+PP2)
         END DO
      END DO
C
      RETURN
C
      END SUBROUTINE INDEXX
      SUBROUTINE ROTATION(F,R,U,NDI)
C>    COMPUTES ROTATION TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI
      DOUBLE PRECISION F(NDI,NDI),R(NDI,NDI),U(NDI,NDI),UINV(NDI,NDI)
C
      CALL MATINV3D(U,UINV,NDI)
C
      R = MATMUL(F,UINV)
      RETURN
      END SUBROUTINE ROTATION
      SUBROUTINE CMATISOMATFIC(CMISOMATFIC,CBAR,CBARI1,CBARI2,
     1                          DISO,UNIT2,UNIT4,DET,NDI)
C>    ISOTROPIC MATRIX: MATERIAL 'FICTICIOUS' ELASTICITY TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1,K1,L1
      DOUBLE PRECISION CMISOMATFIC(NDI,NDI,NDI,NDI),UNIT2(NDI,NDI),
     1                 CBAR(NDI,NDI),DISO(5),
     2                 UNIT4(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION CBARI1,CBARI2
      DOUBLE PRECISION DUDI1,DUDI2,D2UD2I1,D2UD2I2,D2UDI1I2
      DOUBLE PRECISION AUX,AUX1,AUX2,AUX3,AUX4,DET
      DOUBLE PRECISION UIJ,UKL,CIJ,CKL   
C
      DUDI1=DISO(1)
      DUDI2=DISO(2)
      D2UD2I1=DISO(3)
      D2UD2I2=DISO(4)
      D2UDI1I2=DISO(5)
C
      AUX1=FOUR*(D2UD2I1+TWO*CBARI1*D2UDI1I2+
     1           DUDI2+CBARI1*CBARI1*D2UD2I2)
      AUX2=-FOUR*(D2UDI1I2+CBARI1*D2UD2I2)
      AUX3=FOUR*D2UD2I2
      AUX4=-FOUR*DUDI2

      DO I1=1,NDI
        DO J1=1,NDI
           DO K1=1,NDI
              DO L1=1,NDI
                     UIJ=UNIT2(I1,J1)
                     UKL=UNIT2(K1,L1)
                     CIJ=CBAR(I1,J1)
                     CKL=CBAR(K1,L1)
                     AUX=AUX1*UIJ*UKL+
     1                   AUX2*(UIJ*CKL+CIJ*UKL)+AUX3*CIJ*CKL+
     3                   AUX4*UNIT4(I1,J1,K1,L1)
                     CMISOMATFIC(I1,J1,K1,L1)=AUX        
              END DO
           END DO
        END DO
      END DO
C
      RETURN
      END SUBROUTINE CMATISOMATFIC
      SUBROUTINE PROJLAG(C,AA,PL,NDI)
C>    LAGRANGIAN PROJECTION TENSOR
C      INPUTS:
C          IDENTITY TENSORS - A, AA
C          ISOCHORIC LEFT CAUCHY GREEN TENSOR - C
C          INVERSE OF C - CINV
C      OUTPUTS:
C          4TH ORDER SYMMETRIC LAGRANGIAN PROJECTION TENSOR - PL
C
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER I,J,K,L,NDI
C
      DOUBLE PRECISION CINV(NDI,NDI),AA(NDI,NDI,NDI,NDI),
     1                 PL(NDI,NDI,NDI,NDI),C(NDI,NDI)
C
      CALL MATINV3D(C,CINV,NDI)
C
      DO I=1,NDI
         DO J=1,NDI
          DO K=1,NDI
             DO L=1,NDI
              PL(I,J,K,L)=AA(I,J,K,L)-(ONE/THREE)*(CINV(I,J)*C(K,L))
           END DO
          END DO
        END DO
      END DO
C
      RETURN
      END SUBROUTINE PROJLAG
      SUBROUTINE RELAX(QV,HV,AUX1,HV0,PKISO,DTIME,TAU,TETA,NDI)
C>    VISCOUS DISSIPATION: STRESS RELAXATION TENSORS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      DOUBLE PRECISION QV(NDI,NDI),HV(NDI,NDI),PKISO(NDI,NDI),
     1                 HV0(NDI,NDI)
      DOUBLE PRECISION DTIME,TETA,TAU,AUX1,AUX
      INTEGER I1,J1,NDI
C
      QV=ZERO
      HV=ZERO

       AUX=DEXP(-DTIME*((TWO*TAU)**(-ONE)))
       AUX1=TETA*AUX
       DO I1=1,NDI
        DO J1=1,NDI
         QV(I1,J1)=HV0(I1,J1)+AUX1*PKISO(I1,J1)
         HV(I1,J1)=AUX*(AUX*QV(I1,J1)-TETA*PKISO(I1,J1))
        END DO
       END DO
C      
      RETURN
      END SUBROUTINE RELAX
      SUBROUTINE CSISOMATFIC(CISOMATFIC,CMISOMATFIC,DISTGR,DET,NDI)
C>    ISOTROPIC MATRIX: SPATIAL 'FICTICIOUS' ELASTICITY TENSOR
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI
      DOUBLE PRECISION CMISOMATFIC(NDI,NDI),DISTGR(NDI,NDI),
     1                 CISOMATFIC(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION DET  
C
      CALL PUSH4(CISOMATFIC,CMISOMATFIC,DISTGR,DET,NDI)
C
      RETURN
      END SUBROUTINE CSISOMATFIC
      SUBROUTINE HVREAD(HV,STATEV,V1,NDI)
C>    VISCOUS DISSIPATION: READ STATE VARS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,V1,POS
      DOUBLE PRECISION HV(NDI,NDI),STATEV(NSDV)
C
        POS=9*V1-9
        HV(1,1)=STATEV(1+POS)
        HV(1,2)=STATEV(2+POS)
        HV(1,3)=STATEV(3+POS)
        HV(2,1)=STATEV(4+POS)
        HV(2,2)=STATEV(5+POS)
        HV(2,3)=STATEV(6+POS)
        HV(3,1)=STATEV(7+POS)
        HV(3,2)=STATEV(8+POS)
        HV(3,3)=STATEV(9+POS)       
C
      RETURN
C     
      END SUBROUTINE HVREAD
