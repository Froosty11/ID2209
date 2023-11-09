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
	Information_center info_center <- information at 0;
	
	agent target <- nil;
	Store foodStore <- nil;
	Store waterStore <- nil;
	
	int hunger <- rnd(5,70);
	int whenHungry <- 100;
	bool hungry <- false;
	
	int thirst <- rnd(5,70);
	int whenThirsty <- 100;
	bool thirsty <- false;
	
	
	
	reflex getHungry {
		hunger <- hunger + rnd(0,3);
		hungry <- hunger > whenHungry;
		if hungry and target = nil{
			if (foodStore != nil) {
				target <- foodStore;
			}
			else {
				target <- info_center;
			}
		
		}
		write 'hunger: ' + hunger;
		write 'thirst: ' + thirst;
	}
	
	reflex getThirsty {
		thirst <- thirst + rnd(3,5);
		thirsty <- thirst > whenThirsty;
		if thirsty and target = nil{
			if (waterStore != nil) {
				target <- waterStore;
			}
			else {
		
				target <- info_center;
			}
	
		}
	}
	
	reflex beIdle when: target = nil {
		do wander;
	}
	reflex moveToTarget when: target != nil {
		do goto target:target;
	}
	reflex enterStore when: target != nil and location distance_to(target.location) < 2 {
	
		ask Information_center at_distance(2) {
			if (myself.hunger > myself.whenHungry and myself.foodStore = nil) {
				Store food <- askHunger();
				myself.foodStore <- food;
			}
			if (myself.thirst > myself.whenThirsty and myself.waterStore = nil) {
				Store water <- askWater();
				myself.waterStore <- water;
			}
			myself.target <- nil;
		
		}
		
		ask Store at_distance(2) {
			if (self.storetype = 'foodStore' and myself.hungry) {
				write 'äter vid store';
				if (flip(0.3)) {
					write 'reseting foodstore location';
					myself.foodStore <- nil;
				}
				myself.hunger <- 0;
				myself.hungry <- false;
				myself.target <- nil;
			}
			else if (self.storetype = 'waterStore' and myself.thirsty) {
				write 'dricker vid store';
				if (flip(0.5)) {
					write 'reseting waterstore location';
					myself.waterStore <- nil;
				}
				myself.thirst <- 0;
				myself.thirsty <- false;
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
