// traffic light controller 
// 3-street, 20-state version, ew str/left decouple
// inserts all-red after each yellow
// uses enumerated variables for states and for red-yellow-green
// 5 after traffic, 10 max cycles for green when other traffic present
import light_package ::*;           // defines red, yellow, green

// same as Harris & Harris 4-state, but we have added two all-reds
module traffic_light_controller(
  input clk, reset, e_str_sensor, w_str_sensor, e_left_sensor, 
        w_left_sensor, ns_sensor,             // traffic sensors, east-west str, east-west left, north-south 
  output colors e_str_light, w_str_light, e_left_light, w_left_light, ns_light);     // traffic lights, east-west str, east-west left, north-south

  logic s, sb, e, eb, w, wb, l, lb, n, nb;	 // shorthand for traffic combinations:

  assign s  = e_str_sensor || w_str_sensor;					 // str E or W
  assign sb = e_left_sensor || w_left_sensor || ns_sensor;			     // 3 directions which conflict with s
  assign e = e_str_sensor || e_left_sensor;
  assign eb = w_str_sensor || w_left_sensor || ns_sensor;
  assign w = w_str_sensor || w_left_sensor;
  assign wb = ns_sensor || e_str_sensor || e_left_sensor;
  assign l = e_left_sensor || w_left_sensor;
  assign lb = e_str_sensor || w_str_sensor || ns_sensor;
  assign n = ns_sensor;
  assign nb = e_str_sensor || e_left_sensor || w_str_sensor || w_left_sensor;
  
/* fill in the remaining definitions
*/
// ES WS	s
// ES EL	e
// WS WL	w
// EL WL	l
// NS		n
// 20 suggested states, 4 per direction   Y, Z = easy way to get 2-second yellows
// HRRRR = red-red following ZRRRR; ZRRRR = second yellow following YRRRR; 
// RRRRH = red-red following RRRRZ;
  typedef enum {GRRRR, YRRRR, ZRRRR, HRRRR, 	           // ES+WS
  	            RGRRR, RYRRR, RZRRR, RHRRR, 			   // EL+ES
	            RRGRR, RRYRR, RRZRR, RRHRR,				   // WL+WS
	            RRRGR, RRRYR, RRRZR, RRRHR, 			   // WL+EL
	            RRRRG, RRRRY, RRRRZ, RRRRH} tlc_states;    // NS
	tlc_states    present_state, next_state;
	integer ctr5, next_ctr5,       //  5 sec timeout when my traffic goes away
			ctr10, next_ctr10;     // 10 sec limit when other traffic presents

// sequential part of our state machine (register between C1 and C2 in Harris & Harris Moore machine diagram
// combinational part will reset or increment the counters and figure out the next_state
  always_ff @(posedge clk)
	if(reset) begin
	  present_state <= RRRRH;
	  ctr5          <= 0;
	  ctr10         <= 0;
	end  
	else begin
	  present_state <= next_state;
	  ctr5          <= next_ctr5;
	  ctr10         <= next_ctr10;
	end  

// combinational part of state machine ("C1" block in the Harris & Harris Moore machine diagram)
// default needed because only 6 of 8 possible states are defined/used
  always_comb begin
	next_state = RRRRH;                            // default to reset state
	next_ctr5  = 0; 							   // default: reset counters
	next_ctr10 = 0;
	case(present_state)
/* ************* Fill in the case statements ************** */
	
	  GRRRR: begin                                 // ES+WS green 
	  	if(ctr10 == 9) next_state = YRRRR;    					   // timeout if others want a turn
	  	else if(ctr5 == 4 ) next_state = YRRRR;				   // timeout if my traffic goes away
		else begin								   // otherwise stay green
			next_state = GRRRR;
			if(!s || ctr5 > 0) next_ctr5  = ctr5+1;			                       // vacant countdown
			if(s && sb || ctr10 > 0) next_ctr10 = ctr10+1;					   // occupied countdown
	    end
	  end
	  YRRRR: next_state = ZRRRR;
	  ZRRRR: next_state = HRRRR;
// fill in
	  HRRRR: begin                                  // **fill in the blanks in the if ... else if ... chain
	    if (e)
		  next_state = RGRRR;	                         // ES+EL green	     
		else if (w)
		  next_state = RRGRR;							 // WS+WL green
		else if (l)
		  next_state = RRRGR;							 // WL+EL green
		else if (n)
		  next_state = RRRRG;							 // NS green
        else if (s)
		  next_state = GRRRR;
		else
		  next_state = HRRRR;	   
      end
   
	  RGRRR: begin 		                                 // EL+ES green
              // ** fill in the guts **
		if(ctr10 == 9) next_state = RYRRR;    					   // timeout if others want a turn
	  	else if(ctr5 == 4 ) next_state = RYRRR;				   // timeout if my traffic goes away
		else begin								   // otherwise stay green
			next_state = RGRRR;
			if(!e || ctr5 > 0) next_ctr5  = ctr5+1;			                       // vacant countdown
			if(e && eb || ctr10 > 0) next_ctr10 = ctr10+1;					   // occupied countdown
	    end 
	  end
	  RYRRR: next_state = RZRRR;
	  RZRRR: next_state = RHRRR;
	  RHRRR: begin
             // ** fill in the guts **
			if(w)
				next_state = RRGRR;
			else if(l)
				next_state = RRRGR;
			else if(n)
				next_state = RRRRG;
			else if(s)
				next_state = GRRRR;
			else if(e)
				next_state = RGRRR;
			else
				next_state = RHRRR;
      end
	  RRGRR: begin 
	        // ** fill in the guts, etc **
		if(ctr10 == 9) next_state = RRYRR;    					   // timeout if others want a turn
	  	else if(ctr5 == 4 ) next_state = RRYRR;				   // timeout if my traffic goes away
		else begin								   // otherwise stay green
			next_state = RRGRR;
			if(!w || ctr5 > 0) next_ctr5  = ctr5+1;			                       // vacant countdown
			if(w && wb || ctr10 > 0) next_ctr10 = ctr10+1;					   // occupied countdown
	    end
	  end
      // ** fill in the guts to complete 5 sets of R Y Z H progressions **
	  RRYRR: next_state = RRZRR;
	  RRZRR: next_state = RRHRR;
	  RRHRR: begin
		if(l)
			next_state = RRRGR;
		else if(n)
			next_state = RRRRG;
		else if(s)
			next_state = GRRRR;
		else if(e)
			next_state = RGRRR;
		else if(w)
			next_state = RRGRR;
		else
			next_state = RRHRR;
	  end
	  RRRGR: begin
		if(ctr10 == 9) next_state = RRRYR;    					   // timeout if others want a turn
	  	else if(ctr5 == 4 ) next_state = RRRYR;				   // timeout if my traffic goes away
		else begin								   // otherwise stay green
			next_state = RRRGR;
			if(!l || ctr5 > 0) next_ctr5  = ctr5+1;			                       // vacant countdown
			if(l && lb || ctr10 > 0) next_ctr10 = ctr10+1;					   // occupied countdown
	    end
	  end
	  RRRYR: next_state = RRRZR;
	  RRRZR: next_state = RRRHR;
	  RRRHR: begin
		if(n)
			next_state = RRRRG;
		else if(s)
			next_state = GRRRR;
		else if(e)
			next_state = RGRRR;
		else if(w)
			next_state = RRGRR;
		else if(l)
			next_state = RRRGR;
		else
			next_state = RRRHR;
	  end
	  RRRRG: begin
		if(ctr10 == 9) next_state = RRRRY;    					   // timeout if others want a turn
	  	else if(ctr5 == 4 ) next_state = RRRRY;				   // timeout if my traffic goes away
		else begin								   // otherwise stay green
			next_state = RRRRG;
			if(!n || ctr5 > 0) next_ctr5  = ctr5+1;			                       // vacant countdown
			if(n && nb || ctr10 > 0) next_ctr10 = ctr10+1;					   // occupied countdown
	    end
	  end
	  RRRRY: next_state = RRRRZ;
	  RRRRZ: next_state = RRRRH;
	  RRRRH: begin
		if(s)
			next_state = GRRRR;
		else if(e)
			next_state = RGRRR;
		else if(w)
			next_state = RRGRR;
		else if(l)
			next_state = RRRGR;
		else if(n)
			next_state = RRRRG;
		else
			next_state = RRRRH;
	  end
    endcase
  end

// combination output driver  ("C2" block in the Harris & Harris Moore machine diagram)
	always_comb begin
	  e_str_light  = red;                // cover all red plus undefined cases
	  w_str_light  = red;				 // no need to list them below this block
	  e_left_light = red;
	  w_left_light = red;
	  ns_light     = red;
	  case(present_state)      // Moore machine
		GRRRR: begin 
			e_str_light = green;
			w_str_light = green;
		end
		YRRRR,ZRRRR: begin
			e_str_light = yellow;
			w_str_light = yellow;
		end
		RGRRR: begin
			e_str_light = green;
			e_left_light = green;
		end
		RYRRR,RZRRR: begin
			e_str_light = yellow;
			e_left_light = yellow;
		end
		RRGRR: begin
			w_str_light = green;
			w_left_light = green;
		end
		RRYRR,RRZRR: begin
			w_str_light = yellow;
			w_left_light = yellow;
		end
		RRRGR: begin
			e_left_light = green;
			w_left_light = green;
		end
		RRRYR,RRRZR: begin
			e_left_light = yellow;
			w_left_light = yellow;
		end
		RRRRG: begin
			ns_light = green;
		end
		RRRRY,RRRRZ: begin
			ns_light = yellow;
		end
      endcase
end

endmodule