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
