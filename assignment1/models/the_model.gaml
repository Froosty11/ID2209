/**
* Name: themodel
* Based on the internal empty template. 
* Author: andreaslevander
* Tags: 
*/


model themodel

/* Insert your model definition here */

global {
	float worldDimension <- 100#m;
    geometry shape <- square(worldDimension);
    
	int number_of_guests <- 10;
	int number_of_stores <- 4;
	
	point center <- {worldDimension/2,worldDimension/2};
	point info_center_location <- center;
	
	init {
		create Store number: number_of_stores;
		create FestivalGuest number:number_of_guests with: (information_center: info_center_location);
		create Information_center with: (location: info_center_location);
	}
}

species FestivalGuest skills:[moving]{
	point information_center <- nil;
	point targetPoint <- nil;
	
	int hunger <- 0;
	
	reflex getHungry {
		hunger <- hunger + 1;
		write hunger;
	}
	
	reflex beIdle when: targetPoint = nil {
		do wander;
	}
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	reflex enterStore when: location distance_to(targetPoint) < 2 {
		
	}
	aspect base {
		draw circle(1) color: #green;
	}
	
}

species Information_center {
	list<agent> stores <- agents of_species Store;
	init {
		loop s over: stores {
			write s.location;
		}
			
	}

	aspect base {
		draw rectangle(4, 4) color: #blue;
	}
	
}

species Store {

	aspect base {
		draw circle(2) color: #black;
	}
	
}

experiment my_test type: gui {
	output {
		display basic {
			species FestivalGuest aspect:base;
			species Store aspect:base;
			species Information_center aspect:base;
		}
	}
}
