/* signal values of lights and light set statuses */
mtype = { OFF, RED, GREEN, ORANGE, WALK, DONT_WALK };

/* intersection statuses */
mtype = { ENABLED, DISABLED, FAILED };

/* light set events */
mtype = { INIT, ADVANCE, PRE_STOP, STOP, ALL_STOP, NOTIFY, INTERRUPTED };

/* data structure for composite state of a linear light set */
typedef LinearLightSetState  {
        mtype s;         /* light-set status */
        mtype v[2];     /* signal values of pedestrian lights */
        mtype p[2];    /* signal values of vehicular stop lights */
        bool isPedestrianLightGoingToWalk[2];
};

/* data structure for composite state of a turn light set */
typedef TurnLightSetState   {
        mtype s;        /* light set status */
        mtype v[2];    /* signal values of vehicular turn lights */
};

/* these are the only global variables to be used in all properties */
LinearLightSetState sL[2];
TurnLightSetState sT[2];
mtype sI; /* intersection status */

/* usage examples of global variables */
/*
 sL[0].s => current status of linear light set with index 0
 sL[1].v[0] => current signal value of vehicle light 0 of linear light set 1
 sL[1].p[1] => current signal value of pedestrian light 1 of linear light set 1
 sT[1].s => current status of turn light set with index 1
 sT[0].v[0] => current signal value of vehicle light 1 of turn light set 0
 sI => current status of intersection
*/

/* other global variables of your own */ 

/* channels  */
/* chan to_intersection1 = [0] of { mtype }; */
chan to_intersection = [1] of { mtype };
chan SL = [1] of { mtype };
chan event_queue_L [2] = [3] of { mtype };
chan event_queue_T [2] = [3] of { mtype };

/* macros */
/* you¡¯ll need plenty of macros to keep your model organized, clean, non-redundant 
*/

inline enableI() {
 to_intersection ! ENABLED;
}

/* proctype definitions  */

proctype Intersection() {
	run LinearLightSet(0);
	run LinearLightSet(1);
	run TurnLightSet(0);
	run TurnLightSet(1);
	do
		:: atomic{to_intersection?ENABLED -> sI = ENABLED; run scheduling_loop(); break;}
	od
	do
		:: atomic{to_intersection?FAILED -> sI = FAILED; break;}
	od
}

proctype LinearLightSet(bit i) {
	mtype next;
    sL[i].s = OFF;
    sL[i].p[0] = OFF;
    sL[i].p[1] = OFF;
    sL[i].isPedestrianLightGoingToWalk[0] = false;
    sL[i].isPedestrianLightGoingToWalk[1] = false;
    sL[i].v[0] = OFF;
    sL[i].v[1] = OFF;
    /* Ignoring owners and IDs */
    /* Currently ignores the pedestrianOn boolean variable. We might change this later for when switch to RED and ALL_STOP */
	whileloop: event_queue_L[i]?next;
	    if
			:: {(sL[i].s == OFF && next == INIT) -> atomic{sL[i].s = RED; sL[i].p[0] = DONT_WALK; sL[i].p[1] = DONT_WALK; sL[i].v[0] = RED; sL[i].v[1] = RED; SL!NOTIFY}}
	    	:: {(sL[i].s == RED && next == ADVANCE) -> sL[i].s = GREEN; sL[i].p[0] = DONT_WALK; sL[i].p[1] = DONT_WALK; sL[i].v[0] = GREEN; sL[i].v[1] = GREEN; event_queue_L[i]!PRE_STOP}
	    	:: {(sL[i].s == GREEN && next == PRE_STOP) -> sL[i].s = ORANGE; sL[i].p[0] = DONT_WALK; sL[i].p[1] = DONT_WALK; sL[i].v[0] = ORANGE; sL[i].v[1] = ORANGE; event_queue_L[i]!STOP}
	    	:: (sL[i].s == ORANGE && next == STOP) -> atomic{sL[i].s = RED;  sL[i].v[0] = RED; sL[i].v[1] = RED; sL[i].p[0] = WALK; sL[i].p[1] = WALK;  SL!NOTIFY} /*order bug*/
	    	:: {(sL[i].s == RED && next == ALL_STOP) -> atomic{ sL[i].v[0] = RED; sL[i].v[1] = RED; sL[i].p[0] = DONT_WALK; sL[i].p[1] = DONT_WALK; SL!NOTIFY}}
	    	:: {(sL[i].s == OFF && next != INIT) -> SL!INTERRUPTED}
	    	:: {(sL[i].s == RED && (next != ADVANCE && next != ALL_STOP)) -> SL!INTERRUPTED}
	    	:: {(sL[i].s == GREEN && next != PRE_STOP) -> SL!INTERRUPTED}
	    	:: {(sL[i].s == ORANGE && next != STOP) -> SL!INTERRUPTED}
	    fi
    goto whileloop
}

proctype TurnLightSet(bit i) {
	mtype next;
	sT[i].s = OFF;
	sT[i].v[0] = OFF;
	sT[i].v[1] = OFF;
	/* Ignoring owners and IDs */
	whileloop: event_queue_T[i]?next;
		if
	    	:: (sT[i].s == OFF && next == INIT) -> atomic{sT[i].s = RED;  sT[i].v[0] = RED; sT[i].v[1] = RED; SL!NOTIFY}
	    	:: (sT[i].s == RED && next == ADVANCE) -> sT[i].s = GREEN; sT[i].v[0] = GREEN; sT[i].v[1] = GREEN; event_queue_T[i]!PRE_STOP
	    	:: (sT[i].s == GREEN && next == PRE_STOP) -> sT[i].s = ORANGE; sT[i].v[0] = ORANGE; sT[i].v[1] = ORANGE; event_queue_T[i]!STOP
	    	:: (sT[i].s == ORANGE && next == STOP) -> atomic{sT[i].s = RED; sT[i].v[0] = RED; sT[i].v[1] = RED; SL!NOTIFY}
	    	:: (sT[i].s == OFF && next != INIT) -> SL!INTERRUPTED
	    	:: (sT[i].s == RED && (next != ADVANCE && next != ALL_STOP)) -> SL!INTERRUPTED
	    	:: (sT[i].s == GREEN && next != PRE_STOP) -> SL!INTERRUPTED
	    	:: (sT[i].s == ORANGE && next != STOP) -> SL!INTERRUPTED
	    fi
    goto whileloop
}

proctype scheduling_loop() {
	{
		atomic{event_queue_L[0]!INIT; SL?NOTIFY;}
		atomic{event_queue_L[1]!INIT; SL?NOTIFY;}
		atomic{event_queue_T[0]!INIT; SL?NOTIFY;}
		atomic{event_queue_T[1]!INIT; SL?NOTIFY;}
		whileloop:  atomic{event_queue_L[0]!ADVANCE; SL?NOTIFY} 
					atomic{event_queue_L[1]!ADVANCE; SL?NOTIFY}
					atomic{event_queue_L[0]!ALL_STOP; SL?NOTIFY}
					atomic{event_queue_L[1]!ALL_STOP; SL?NOTIFY}
					atomic{event_queue_T[0]!ADVANCE; SL?NOTIFY}
					atomic{event_queue_T[1]!ADVANCE; SL?NOTIFY}
		goto whileloop
	} unless { SL?INTERRUPTED -> to_intersection!FAILED}
}
