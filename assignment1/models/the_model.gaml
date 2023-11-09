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
		create Store with: (storetype: 'waterStore');
		create Store with: (storetype: 'foodStore');
		create Store number: number_of_stores - 2;
		create Information_center with: (location: info_center_location);
		create FestivalGuest number:number_of_guests;
	
	}
}

species FestivalGuest skills:[moving]{
	list<Information_center> information <- agents of_species Information_center;
	agent target <- nil;
	Store foodStore <- nil;
	Store waterStore <- nil;
	
	int hunger <- rnd(5,70);
	int whenHungry <- 100;
	
	int thirst <- rnd(5,70);
	int whenThirsty <- 100;
	
	init {
		loop s over: information {
			write s;
		}
	}
	
	
	reflex getHungry {
		hunger <- hunger + rnd(0,3);
		if hunger > whenHungry {
			if (foodStore != nil) {
				target <- foodStore;
			}
			else {
				Information_center asd <- information at 0;
				target <- asd;
			}
	
		}
	}
	
	reflex getThirsty {
		thirst <- thirst + rnd(0,3);
		if thirst > whenThirsty {
			if (waterStore != nil) {
				target <- waterStore;
			}
			else {
				Information_center asd <- information at 0;
				target <- asd;
			}
	
		}
	}
	
	reflex beIdle when: target = nil {
		do wander;
	}
	reflex moveToTarget when: target != nil {
		do goto target:target;
	}
	reflex enterStore when: target != nil and location distance_to(target.location) < 5 {
	
		ask Information_center at_distance(5) {
			if (myself.hunger > myself.whenHungry) {
				Store food <- askHunger();
				myself.foodStore <- food;
			}
			else if (myself.thirst > myself.whenThirsty) {
				Store water <- askWater();
				myself.waterStore <- water;
			}
		
		}
		
		ask Store at_distance(5) {
			if (self.storetype = 'foodStore' and myself.hunger > myself.whenHungry) {
				write 'äter vid store';
				if (flip(0.3)) {
					myself.foodStore <- nil;
				}
				myself.hunger <- 0;
				myself.target <- nil;
			}
			else if (self.storetype = 'waterStore' and myself.thirst > myself.whenThirsty) {
				write 'dricker vid store';
				if (flip(0.3)) {
					myself.waterStore <- nil;
				}
				myself.thirst <- 0;
				myself.target <- nil;
			}
		}
	}
	aspect base {
		draw circle(1) color: #green;
	}
	
}

species Information_center {
	list<Store> stores <- agents of_species Store;
	list<Store> foodStores <- nil;
	list<Store> waterStores <- nil;
	init {
		loop s over: stores {
			if (s.storetype = 'foodStore') {
				foodStores <- foodStores + s;
			}
			if (s.storetype = 'waterStore') {
				waterStores <- waterStores + s;
			}
		}
			
	}
	
	
	Store askHunger {
			int i <- rnd(0, length(foodStores) - 1);
			Store test <- foodStores at i;
			write 'returning hunger store';
			write i;
			write test.location;
			return test;
		
	}
	
	Store askWater {
		int i <- rnd(0, length(waterStores) - 1);
		return waterStores at i;
	}

	aspect base {
		draw rectangle(4, 4) color: #red;
	}
	
}

species Store {
	string storetype <- flip(0.5) ? 'waterStore' : 'foodStore';

	aspect base {
		draw circle(2) color: storetype = 'waterStore' ? #blue : #brown;
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
