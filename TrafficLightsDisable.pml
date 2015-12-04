#include "TrafficLights.pml"

#define isLinearLightVehicle(index, color) (sL[index].v[0]==color && sL[index].v[1]==color)
#define isAllLinearLightVehicle(color) (isLinearLightVehicle(0,color) && isLinearLightVehicle(1,color))

#define isLinearLightPedestrian(index, color) (sL[index].p[0]==color && sL[index].p[1]==color)
#define isAllLinearLightPedestrian(color) (isLinearLightPedestrian(0,color) && isLinearLightPedestrian(1,color))

#define isTurnLightVehicle(index, color) (sT[index].v[0]==color && sT[index].v[1]==color)
#define isAllTurnLightVehicle(color) (isTurnLightVehicle(0,color) && isTurnLightVehicle(1,color))

ltl disableSuccess { (sI == DISABLED) -> [](isAllLinearLightVehicle(OFF) && isAllLinearLightPedestrian(OFF) && isAllTurnLightVehicle(OFF)) }
 
init {
	run Intersection();
	enableI(); /* statements or macro that enables intersection */
	disableI(); /* statements or macro that disables intersection */
}

