/**
* Name: themodel
* Based on the internal empty template. 
* Author: andreaslevander & Edvin Frosterud
* Tags: 
*/


model mod2

/* Insert your model definition here */

global {
	float worldDimension <- 100#m;
    geometry shape <- square(worldDimension);
    
    
    //Editable variables.
	int number_of_guests <- 10;
	int number_of_stores <- 4;
	int number_of_security <- 1;
	
	int leastHunger <- 0;
	int mostHunger <- 3;
	
	int leastThirst <- 3;
	int mostThirst <- 5;
	
	int whenHungry <- 100;
	int whenThirsty <- 100;
	
	float forgetOdds <- 0.3;
	
	point center <- {worldDimension/2,worldDimension/2};
	point info_center_location <- center;
	
	
	init {
		create Store with: (storetype: 'waterStore');
		create Store with: (storetype: 'foodStore');
		create Store number: number_of_stores - 2;
		create SecurityGuard number: number_of_security;
		create Information_center with: (location: info_center_location);
		create FestivalGuest with: (forgetOdds: 0.0, printMovement: true, angry: false, name: "NoResetGuest", whenHungry: whenHungry, whenThirsty: whenThirsty);
		create FestivalGuest with: (forgetOdds: 1.0, printMovement: true, angry: false, name: "AlwaysResetGuest", whenHungry: whenHungry, whenThirsty: whenThirsty);
		//create FestivalGuest number:number_of_guests - 2 with: (forgetOdds: forgetOdds, whenHungry: whenHungry, whenThirsty: whenThirsty);
		//create DutchAuctioneer with: (name: 'DutchAuctioneer');
		create EnglishAuctioneer with: (name: 'EnglishAuctioneer');
		
	
	}
}

species DutchAuctioneer skills: [fipa] {
	
	float price <- 1000.0;
	float minPrice <- 50.0;
	int item <- 1; 
	
	reflex send_cfp_to_participants when: (time = 1) {
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		do start_conversation to: list(FestivalGuest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price] ;
	}
	reflex receive_refuse_messages when: empty(proposes) and !empty(refuses) {
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		price <- price * 0.9;
		if price <= minPrice {
			loop r over: refuses {
				write '\t' + name + ' refuse from: ' + r.sender;
				do cfp message: r contents: [price];
				write '\t' + name + ' sends new price to ' + agent(r.sender).name + ' with content ' + [price];
			}
		}
	}
	reflex receive_buyer_proposal when : !empty(proposes){
		write '(Time ' + time + '): ' + name + ' receives buy messages: ' + proposes;
		message buyerMessage <- proposes at 0; 
		do accept_proposal message: buyerMessage contents:['Congratulations!'];
		write "Auction complete! winner: " + buyerMessage.sender;
		
	
		loop r over: proposes {
			write '\t' + name + ' sends reject to: ' + r.sender; 
			do reject_proposal message: r contents: ['Not interested in your proposal'] ;
		}
		
		price <- 100000.0;
		item <- item + 1;
		write '(Time ' + time + '): ' + name + ' sends a new auction cfp message to all participants item: ' + item;
		do start_conversation to: list(FestivalGuest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price] ;
		
	}
}

species EnglishAuctioneer skills: [fipa] {
	
	float price <- 100.0;
	int item <- 1; 
	
	reflex send_cfp_to_participants when: (time = 1) {
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		do start_conversation to: list(FestivalGuest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price] ;
	}
	reflex receive_refuse_messages when: !empty(refuses) {
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		
		loop r over: refuses {
			write '\t' + name + ' refuse from: ' + r.sender;
		
		}
	}
	
	reflex receive_buyer_proposal when : !empty(proposes){
		write '(Time ' + time + '): ' + name + ' receives buy messages: ' + proposes;
		
		if length(proposes) > 1 {
			loop r over: proposes {
				write '\t' + name + ' sends new cfp to: ' + r.sender;
				do reject_proposal message: r contents: [price];

			}
			price <- price * 1.1;
			do start_conversation to: list(FestivalGuest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price];
		} else {
			message buyerMessage <- proposes at 0; 
			do accept_proposal message: buyerMessage contents:[price, 'Congratulations you have won an item!'];
			write "Auction complete! winner: " + buyerMessage.sender;
			
			price <- 100.0;
			item <- item + 1;
			write '(Time ' + time + '): ' + name + ' sends a new auction cfp message to all participants item: ' + item;
			do start_conversation to: list(FestivalGuest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price];
		}
		
		
		
		
	}
}

species FestivalGuest skills:[moving, fipa]{
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
	
	bool angry <- flip(0.3);
	
	float forgetOdds <- 0.3;
	
	float distanceMoved <- 0.0;
	bool printMovement <- false;
	int movementPrintCycle <- 0;
	
	float budget <- rnd(100, 1000) as float;
		reflex receive_accept when: !empty(accept_proposals) {
		message proposalFromInitiator <- accept_proposals[0];
		write '(Time ' + time + '): ' + name + ' receives a accept message from ' + agent(proposalFromInitiator.sender).name + ' with content ' + proposalFromInitiator.contents;
		
		float price <- float(proposalFromInitiator.contents[0]);
		budget <- budget - price;
		
	}
	
	reflex receive_cfp_from_auctioneer when: !empty(cfps) {
		message proposalFromInitiator <- cfps[0];
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ' with content ' + proposalFromInitiator.contents;
		
		list msg <- list(proposalFromInitiator.contents);
		int price <- int(msg at 0);
		//write price;
			
		if (price <= budget) {
			write '\t' + name + ' accepts price: ' + price + ' budget: ' + budget;
			do propose message: proposalFromInitiator contents: ['Sure, I will buy this Item'];
		}
		else {
			write '\t' + name + ' refuses price: ' + price + ' budget: ' + budget;
			do refuse message: proposalFromInitiator contents: ['Reject proposal'];
		}
		}
	

		
		
		
	
	
	// prints movement every x cycles if we want
	reflex printMovement {
		movementPrintCycle <- movementPrintCycle + 1;
		if (printMovement and movementPrintCycle = 10) {
			movementPrintCycle <- 0;
			write name + " distance moved: " + distanceMoved;
		}
	}
	
	reflex getHungry {
		hunger <- hunger + rnd(leastHunger, mostHunger); //How much hunger should be lost every tick.  We measure hunger/thirst as positive is more hungry. 
		hungry <- hunger > whenHungry;
		if hungry and target = nil{
			write("Hungry!");
			if (foodStore != nil) {
				target <- foodStore;
			}
			else {
				target <- info_center;
				write(" Going to info");
			}
		
		}
		//write 'hunger: ' + hunger;
		//write 'thirst: ' + thirst;
	}
	
	reflex getThirsty {
		thirst <- thirst + rnd(leastThirst,mostThirst);  //How much thirst should be lost every tick. We measure hunger/thirst as positive is more hungry. 
		thirsty <- thirst > whenThirsty;
		if thirsty and target = nil{
			write("Thirsty!");
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
		distanceMoved <- distanceMoved + speed;
		do goto target:target;
	}
	reflex enterStore when: target != nil and location distance_to(target.location) < 2 {
	
		ask Information_center at_distance(2) {
			if (myself.hunger > myself.whenHungry and myself.foodStore = nil) {
				Store food <- askHunger();
				write("Asked info, target changed");
				myself.foodStore <- food;
			}
			if (myself.thirst > myself.whenThirsty and myself.waterStore = nil) {
				Store water <- askWater();
				write("Asked info, target changed");
				myself.waterStore <- water;
			}
			if (myself.angry and self.guard.target = nil) {
				self.guard.target <- myself;
			}
			myself.target <- nil;
		
		}
		
		ask Store at_distance(2) {
			if (self.storetype = 'foodStore' and myself.hungry) {
				write 'eating at store';
				if (flip(myself.forgetOdds)) {
					write 'reseting foodstore location';
					myself.foodStore <- nil;
				}
				myself.hunger <- 0;
				myself.hungry <- false;
				myself.target <- nil;
			}
			else if (self.storetype = 'waterStore' and myself.thirsty) {
				write 'drinking at store';
				if (flip(myself.forgetOdds)) {
					//write 'reseting waterstore location';
					myself.waterStore <- nil;
				}
				myself.thirst <- 0;
				myself.thirsty <- false;
				myself.target <- nil;
			}
		}
	}
	aspect base {
		draw circle(1) color: angry ? #red : #green;
	}
	
}

species Information_center {
	list<Store> stores <- agents of_species Store;
	list<Store> foodStores <- nil;
	list<Store> waterStores <- nil;
	
	list<SecurityGuard> guards <- agents of_species SecurityGuard;
	SecurityGuard guard <- guards at 0;
	
	
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

species SecurityGuard skills:[moving]{
	agent target <- nil;
	
	init {
		speed <- 1.2;
	}
	
	reflex beIdle when: target = nil {
		do wander;
	}
	reflex moveToTarget when: target != nil {
		do goto target:target;
		
		if (!dead(target) and location distance_to(target.location) < 2) {
			ask target {
				do die;
			}
			target <- nil;
		}
		
	}
	
	

	aspect base {
		draw triangle(4) color: #black;
	}
	
}

experiment my_test type: gui {
	output {
		display basic {
			species FestivalGuest aspect:base;
			species Store aspect:base;
			species Information_center aspect:base;
			species SecurityGuard  aspect:base;
		}
	}
}
