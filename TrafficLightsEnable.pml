#include "TrafficLights.pml"

#define isLinearLightVehicle(index, color) (sL[index].v[0]==color && sL[index].v[1]==color)
#define isAllLinearLightVehicle(color) (isLinearLightVehicle(0,color) && isLinearLightVehicle(1,color))

#define isLinearLightPedestrian(index, color) (sL[index].p[0]==color && sL[index].p[1]==color)
#define isAllLinearLightPedestrian(color) (isLinearLightPedestrian(0,color) && isLinearLightPedestrian(1,color))

#define isTurnLightVehicle(index, color) (sT[index].v[0]==color && sT[index].v[1]==color)
#define isAllTurnLightVehicle(color) (isTurnLightVehicle(0,color) && isTurnLightVehicle(1,color))

ltl safePedestrian{ []((sL[0].p[0]==WALK -> (isLinearLightVehicle(0,RED) && isAllTurnLightVehicle(RED)))
					&& (sL[0].p[1]==WALK -> (isLinearLightVehicle(0,RED) && isAllTurnLightVehicle(RED)))
					&& (sL[1].p[0]==WALK -> (isLinearLightVehicle(1,RED) && isAllTurnLightVehicle(RED)))
					&& (sL[1].p[1]==WALK -> (isLinearLightVehicle(1,RED) && isAllTurnLightVehicle(RED)))) }

ltl safeStraightTraffic {[]((sL[0].v[0]==GREEN -> (isLinearLightVehicle(1,RED) && isAllTurnLightVehicle(RED)))
						 && (sL[0].v[1]==GREEN -> (isLinearLightVehicle(1,RED) && isAllTurnLightVehicle(RED)))) }
						 
ltl safeLeftTurn { [] ((sT[0].v[0]==GREEN -> (isAllLinearLightVehicle(RED) && isTurnLightVehicle(1,RED)))
					&& (sT[0].v[1]==GREEN -> (isAllLinearLightVehicle(RED) && isTurnLightVehicle(1,RED)))
					&& (sT[1].v[0]==GREEN -> (isAllLinearLightVehicle(RED) && isTurnLightVehicle(0,RED)))
					&& (sT[1].v[1]==GREEN -> (isAllLinearLightVehicle(RED) && isTurnLightVehicle(0,RED))))}

ltl pedestrianDelay { [](<>(sL[0].p[0]==WALK) -> ((sL[0].p[0]!=WALK) U ((isLinearLightVehicle(0,RED) && isAllTurnLightVehicle(RED)) && (sL[0].p[0]!=WALK)))) }

ltl straightTrafficDelay {[](<>(isLinearLightVehicle(0,GREEN)) -> (!isLinearLightVehicle(0,GREEN) U ((isAllLinearLightVehicle(RED) && isAllLinearLightPedestrian(DONT_WALK)) && !isLinearLightVehicle(0,GREEN))))}

ltl leftTurnDelay {[](<>(isTurnLightVehicle(0,GREEN)) -> ((!isTurnLightVehicle(0,GREEN)) U ((isAllLinearLightVehicle(RED) && isAllLinearLightPedestrian(DONT_WALK)) && !isTurnLightVehicle(0,GREEN))))}

ltl productivePedestrian { []<>(sL[0].p[0]==WALK) }

ltl productiveStraightGoingVehicle { []<>(sL[0].v[0]==GREEN) }

ltl productiveLeftTurningVehicle { []<>(sT[0].v[0]==GREEN) }

ltl signalOrderOrange { []((sT[0].v[0]==GREEN) -> ((sT[0].v[0]==GREEN) U (sT[0].v[0]==ORANGE))) }

ltl signalOrderRed { []((sT[0].v[0]==ORANGE) -> ((sT[0].v[0]==ORANGE) U (sT[0].v[0]==RED))) }

ltl signalOrderGreen { []((sT[0].v[0]==RED) -> ((sT[0].v[0]==RED) U (sT[0].v[0]==GREEN))) }


/* variation of above for other lights, your properties, won¡¯t be checked by Vocareum */
/*
ltl safePedestrian01 { ... }
ltl safePedestrian11 { ... }
ltl safeStraightTraffic { ...  };
*/


init {
	run Intersection();
	enableI(); /* statements or macro that enables intersection */
}
