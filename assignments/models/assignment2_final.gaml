/**
* Name: Assignment 2 Final
* Based on the internal empty template. 
* Author: andreaslevander, Edvin Frosterud
* Tags: 
*/


model test

global {

	init {
		create FestivalGuest number: 2 with: (interest: 'Clothes');
		create FestivalGuest number: 2 with: (interest: 'Movies');
		create FestivalGuest number: 2 with: (interest: 'Books');
		create DutchAuctioneer with: (name: 'DutchAuctioneer', category: 'Books');
		create EnglishAuctioneer with: (name: 'EnglishAuctioneer', category: 'Movies');
		create SealedBidAuctioneer with: (name: 'SealedBidAuctioneer', category: 'Clothes');
		
	
	}
}

species SealedBidAuctioneer skills: [fipa] {
	float minPrice <- 100.0;
	int item <- 0;
	float total <- 0.0;
	list<agent> participants <- [];
	
	message highestBidder <- nil;
	float startTime <- 1.0;
	string category <- "Clothes";
	string type <- "SealedBid";
	bool inAuction <- false;
	
	action startAuction {
		participants <- [];
		highestBidder <- nil;
		minPrice <- 100.0;
		item <- item + 1;
		write '(Time ' + time + '): ' + name + ' starting new auction item: ' + item;
		do start_conversation to: list(FestivalGuest) protocol: 'fipa-propose' performative: 'inform' contents: ['Starting new auction', category, item, minPrice] ;
	}
	
	action endAuction (message winner) {
		if (winner.contents != nil) {
			float winningBid <- winner.contents[1] as float;
			do accept_proposal message: winner contents:[winningBid, 'Congratulations you have won an item!'];
			total <- total + winningBid;
			write "Auction complete! winner: " + winner.sender;
		}
		
		startTime <- time + 5;
		highestBidder <- nil;
		inAuction <- false;
		
		if length(participants) >= 1 {
			do start_conversation to: participants performative: 'inform' contents: ['Auction over'] ;
		}
	}
	
	reflex start when: (time = startTime) {
		do startAuction;
		 
	}
	
	reflex timeout when: time > startTime + 2 and !inAuction {
		write '(Time ' + time + '): ' + name + ' no participants canceling auction ';
		do endAuction(highestBidder);
	}
	
	reflex join_auction when: !empty(accept_proposals){
		loop p over: accept_proposals {
			add p.sender to: participants;
			do inform message: p contents: ["added to auction"];
		}
		
		write '(Time ' + time + '): ' + name + ' starting auction with participants: ' + participants;
		inAuction <- true;
		do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'cfp' contents: [minPrice, type, item];
		
		
	} 
	
	
	reflex no_new_bids when: empty(proposes) and inAuction{
		// no bidders at all
		if (time > startTime + 2){
			write 'no bidders';
			do endAuction(highestBidder);
	
		}
	}
	
	reflex receive_buyer_proposal when : !empty(proposes){
		write '(Time ' + time + '): ' + name + ' receives buy messages: ' + proposes;
		
		
		highestBidder <- proposes[0];
		loop r over: proposes {
				if float(r.contents[1]) > float(highestBidder.contents[1]) {
					highestBidder <- r;
				}
			}
		
		do endAuction(highestBidder);
		
	}
}

species EnglishAuctioneer skills: [fipa] {
	float price <- 100.0;
	int item <- 0;
	float total <- 0.0;
	list<agent> participants <- [];
	
	message highestBidder <- nil;
	float startTime <- 1.0;
	string category <- "Movies";
	string type <- "English";
	bool inAuction <- false;
	
	action startAuction {
		participants <- [];
		highestBidder <- nil;
		price <- 100.0;
		item <- item + 1;
		write '(Time ' + time + '): ' + name + ' starting new auction item: ' + item;
		do start_conversation to: list(FestivalGuest) protocol: 'fipa-propose' performative: 'inform' contents: ['Starting new auction', category, item, price] ;
	}
	
	action endAuction (message winner) {
		if (winner.contents != nil) {
			float winningBid <- winner.contents[1] as float;
			do accept_proposal message: winner contents:[winningBid, 'Congratulations you have won an item!'];
			total <- total + winningBid;
			write "Auction complete! winner: " + winner.sender;
		}
		
		startTime <- time + 5;
		highestBidder <- nil;
		inAuction <- false;
		
		if length(participants) >= 1 {
			do start_conversation to: participants performative: 'inform' contents: ['Auction over'] ;
		}
	}
	
	reflex start when: (time = startTime) {
		do startAuction;
		 
	}
	
	reflex timeout when: time > startTime + 2 and !inAuction {
		write '(Time ' + time + '): ' + name + ' no participants canceling auction ';
		do endAuction(highestBidder);
	}
	
	reflex join_auction when: !empty(accept_proposals){
		loop p over: accept_proposals {
			add p.sender to: participants;
			do inform message: p contents: ["added to auction"];
		}
		
		write '(Time ' + time + '): ' + name + ' starting auction with participants: ' + participants;
		inAuction <- true;
		do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'cfp' contents: [price, type, item];
		
		
	} 
	
	
	reflex no_new_bids when: empty(proposes) and inAuction{
		//write highestBidder;
		if (highestBidder.contents != nil) {
			write 'no new proposals highest bid wins!';
			do endAuction(highestBidder);
		} 
		// no bidders at all
		else if (time > startTime + 2){
			write 'no bidders';
			do endAuction(highestBidder);
	
		}
	}
	
	reflex receive_buyer_proposal when : !empty(proposes){
		write '(Time ' + time + '): ' + name + ' receives buy messages: ' + proposes;
		
		// more than one bidder
		if length(proposes) > 1 {
			highestBidder <- proposes[0];
			loop r over: proposes {
				write '\t' + name + ' reject proposal to: ' + r.sender;
				do reject_proposal message: r contents: [price];

			}
			price <- price + 10;
			do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'cfp' contents: [price, type, item];
		} else {
			// only one bidder
			message buyerMessage <- proposes at 0; 
			do endAuction(buyerMessage);
		}
		
	}
}

species DutchAuctioneer skills: [fipa] {
	
	float price <- 1000.0;
	float minPrice <- 50.0;
	float total <- 0.0;
	int item <- 0; 
	list<agent> participants <- [];
	bool inAuction <- false;
	float startTime <- 1.0;
	string category <- "Books";
	string type <- "Dutch";
	
	action startAuction {
		participants <- [];
		price <- 1000.0;
		item <- item + 1;
		write '(Time ' + time + '): ' + name + ' starting new auction item: ' + item;
		inAuction <- true;
		do start_conversation to: list(FestivalGuest) protocol: 'fipa-propose' performative: 'inform' contents: ['Starting new auction', category, item, price] ;
	}
	
	action endAuction (message winner) {
		float winningBid <- winner.contents[1] as float;
		do accept_proposal message: winner contents:[winningBid, 'Congratulations you have won an item!'];
		total <- total + winningBid;
		write "Auction complete! winner: " + winner.sender;
		
		startTime <- time + 5;
		inAuction <- false;
		do start_conversation to: participants performative: 'inform' contents: ['Auction over'];
	}
	
	reflex start when: (time = startTime) {
		do startAuction;
		 
	}
	
	reflex join_auction when: !empty(accept_proposals){
		loop p over: accept_proposals {
			add p.sender to: participants;
			do inform message: p contents: ["added to auction"];
		}
		write '(Time ' + time + '): ' + name + ' starting auction with participants: ' + participants;
		do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'cfp' contents: [price, type, item];
	} 
	

	reflex receive_refuse_messages when: empty(proposes) and !empty(refuses) {
		if (inAuction) {
			write '(Time ' + time + '): ' + name + ' receives refuse messages';
			price <- price * 0.9;
			
			if price > minPrice {
				loop r over: refuses {
					write '\t' + name + ' refuse from: ' + r.sender;
					do cfp message: r contents: [price, type, item];
					write '\t' + name + ' sends new price to ' + agent(r.sender).name + ' with content ' + [price];
				}
			} else {
				write 'min price reached, Auction over';
				inAuction <- false;
				startTime <- time + 5;
				do start_conversation to: participants performative: 'inform' contents: ['Auction over'];
			}
		} else {
			loop r over: refuses {
				do inform message: r contents: ['Auction over'];
			}
		}
		
	}
	reflex receive_buyer_proposal when : !empty(proposes){
		write '(Time ' + time + '): ' + name + ' receives buy messages: ' + proposes;
		message buyerMessage <- proposes at 0; 
		do endAuction(buyerMessage);
		
	
		loop r over: proposes {
			write '\t' + name + ' sends reject to: ' + r.sender; 
			do reject_proposal message: r contents: ['Not interested in your proposal'] ;
		}
		
	}
}

species FestivalGuest skills:[fipa]{
	
	float budget <- rnd(100.0, 1000.0);
	float willingToSpend <- rnd(0, budget);
	bool inAuction <- false;
	string interest <- "Movies";
	
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
		string type <- msg[1];
		
		
		if (type = "Dutch" or type = "English") {
			if (price <= willingToSpend) {
				write '\t' + name + ' accepts price: ' + price + ' willing to spend: ' + willingToSpend;
				do propose message: proposalFromInitiator contents: ['Sure, I will buy this Item', price, name];
			}
			else {
				write '\t' + name + ' refuses price: ' + price + ' willing to spend: ' + willingToSpend;
				do refuse message: proposalFromInitiator contents: ['Reject proposal', price, name];
			}
		} else if (type = "SealedBid") {
			write '\t' + name + ' making sealed bid: ' + willingToSpend;
			do propose message: proposalFromInitiator contents: ['I am willing to spend', willingToSpend, name];
		}
	}
		
	
	reflex join_auction when: !empty(informs) {
		loop i over: informs {
			string msg <- i.contents[0];
			
			if (msg = "Starting new auction") {
				string category <- i.contents[1];
				if (!inAuction and category = interest) {
					willingToSpend <- rnd(1, budget);
					write '(Time ' + time + '): ' + name + ' joining auction with ' + i.sender;
					write '\t' + ' willing to spend: ' + willingToSpend;
					write '\t' + ' budget left: ' + budget;
					do accept_proposal message: i contents: ['agree to join auction'];
					inAuction <- true;
				} else {
					write '(Time ' + time + '): ' + name + ' not joining auction with ' + i.sender;
					do reject_proposal message: i contents: ['not joining auction'];
				}
			} else if (msg = "Auction over") {
				write '(Time ' + time + '): ' + name + ' recieved auction over';
				inAuction <- false;
			}
			
		}
	}
	}



experiment asd type: gui  {	
	
	output {
		display my_chart {
			
			chart "Auction totals" {
				if length(EnglishAuctioneer) > 0 {
					data "English Auction" value: list(EnglishAuctioneer)[0].total;
				
				if length(DutchAuctioneer) > 0 {
					data "Dutch Auction" value: list(DutchAuctioneer)[0].total;
				}
				if length(SealedBidAuctioneer) > 0 {
					data "SealedBid Auction" value: list(SealedBidAuctioneer)[0].total;
				}
				
			}
		
		}
	}

}
}
