import influence;
import hooks;
import util.formatting;
import icons;
import notifications;
from influence import ICardNotification, InfluenceStore;
from planet_effects import GenericEffect;
from bonus_effects import BonusEffect;
import hook_globals;
import target_filters;
import systems;
import statuses;


#section server
from influence_global import startInfluenceVote, createInfluenceEffect, dismissEffect, getInfluenceEffectOwner, getInfluenceEffect, rotateInfluenceStack, fillInfluenceStackWithLeverage, playInfluenceCard_server;
from notifications import NotificationStore;
#section shadow
from influence_global import getInfluenceEffectOwner;
#section all

// Three budget cycles.
const double SANCTION_TIMER = 3.0 * 60.0 * 3.0;

//LevelPlayCost(<Target>, <Factor> = 1.0)
// Increase the play cost of the card by <Factor> for every level
// that <Target> has.
class LevelPlayCost : InfluenceCardEffect {
	Document doc("Increases the cost to play this card for each level the target has.");
	Argument targ(TT_Object);
	Argument effective("Amount", AT_Decimal, "1.0", doc="Increase per level.");

	int getPlayCost(const InfluenceCard@ card, const InfluenceVote@ vote, const Targets@ targets) const {
		if(targets is null)
			return INDETERMINATE;
		Object@ obj = arguments[0].fromConstTarget(targets).obj;
		if(obj is null)
			return INDETERMINATE;
		if(obj.isStar)
			@obj = obj.region;
		if(obj.isRegion) {
			int levels = 0;
			for(uint i = 0, cnt = obj.planetCount; i < cnt; ++i) {
				Planet@ pl = obj.planets[i];
				if(pl !is null && pl.owner !is null && pl.owner.valid && pl.owner !is card.owner) {
					levels += pl.level;
				}
			}
			return round(double(levels) * arguments[1].decimal);
		}
		else {
			if(!obj.hasSurfaceComponent)
				return 0;
			return round(double(obj.level) * arguments[1].decimal);
		}
	}
};

//SquaredLevelPlayCost(<Target>, <Factor> = 1.0)
// Increase the play cost of the card by <Factor> times the <Target> planet level squared.
class SquaredLevelPlayCost : InfluenceCardEffect {
	Document doc("Increases the cost to play this card for each level the target has.");
	Argument targ(TT_Object);
	Argument effective("Amount", AT_Decimal, "1.0", doc="Increase per level.");

	int getPlayCost(const InfluenceCard@ card, const InfluenceVote@ vote, const Targets@ targets) const {
		if(targets is null)
			return INDETERMINATE;
		Object@ obj = arguments[0].fromConstTarget(targets).obj;
		if(obj is null)
			return INDETERMINATE;
		if(obj.isStar)
			return INDETERMINATE;
		if(obj.isRegion)
			return INDETERMINATE;
		else {
			if(!obj.hasSurfaceComponent)
				return 0;
			return round(double(obj.level * obj.level) * arguments[1].decimal);
		}
	}
};

//ImposeSanctions(<Event>, <Target>)
// Impose economic sanctions on <Target> planet if <Event> happens.
// <Event> should be one of 'pass' or 'fail'.
class ImposeSanctions : InfluenceVoteEffect {
	Document doc("Imposes economic sanctions on a target planet if the vote passes or fails.");
	Argument event("Event", AT_PassFail, doc="Either 'pass' or 'fail' to choose when the result occurs.");
	Argument targ("Target", TT_Object);

#section server
	void onEnd(InfluenceVote@ vote, bool passed, bool withdrawn) const override {
		Object@ obj = targ.fromTarget(vote.targets).obj;
		auto@ status = getStatusType("Blockaded");
		if(passed == event.boolean)
		for(uint lev = 0; lev <= obj.level; ++lev) {
			obj.addStatus(status.id, timer=SANCTION_TIMER);
			obj.addStatus(status.id, timer=SANCTION_TIMER);
			obj.addStatus(status.id, timer=SANCTION_TIMER);
			obj.addStatus(status.id, timer=SANCTION_TIMER);
			obj.addStatus(status.id, timer=SANCTION_TIMER);
			obj.addStatus(status.id, timer=SANCTION_TIMER);
			obj.addStatus(status.id, timer=SANCTION_TIMER);
			obj.addStatus(status.id, timer=SANCTION_TIMER);
			obj.addStatus(status.id, timer=SANCTION_TIMER);
			obj.addStatus(status.id, timer=SANCTION_TIMER);
		}
	}
#section all
};

//NotifyAllTargetEmpire(<Text>)
// Send a notification to all empires, referencing a target empire.
class NotifyAllTargetEmpire : InfluenceCardEffect {
	Document doc("Sends a notification message to all other empires anonymously, referencing a target empire.");
	Argument msg("Text", AT_Locale, doc="Message to send.");
	Argument contact("Contact Only", AT_Boolean, "True", doc="Whether to limit the notification to contacted empires.");

	bool formatNotification(const InfluenceCard@ card, const InfluenceCardPlayEvent@ event, const ICardNotification@ notification, string& text) const override {
		auto@ n = cast<const CardNotification>(notification);
	
		array<string> args;
		args.insertLast(formatEmpireName(card.owner));
		args.insertLast(card.formatTitle());
		args.insertLast(formatEmpireName(n.relatedObject.owner));
		event.targets.formatInto(args);

		text = format(arguments[0].str, args);
		return true;
	}

#section server
	void onPlay(InfluenceCard@ card, Targets@ targets) const override {
		for(uint i = 0, cnt = getEmpireCount(); i < cnt; ++i) {
			auto@ emp = getEmpire(i);
			if(!emp.major)
				continue;
			if(emp is card.owner)
				continue;
			if(arguments[1].boolean && card.owner.ContactMask & emp.mask == 0)
				continue;

			CardNotification n;
			n.event.card = card;
			n.event.targets = targets;
			@n.event.card.owner = defaultEmpire;

			cast<NotificationStore>(emp.Notifications).addNotification(emp, n);
		}
	}
#section all
};

//GiveLeverageToOwner(<Object>, <Quality Factor> = 1.0)
// Give the owner of <Object> leverage on the card's empire.
class GiveLeverageToOwner : InfluenceCardEffect {
	Document doc("Generate leverage against the owner of the targeted object.");
	Argument targ("Object", TT_Object);
	Argument qual("Quality Factor", AT_Decimal, "1.0", doc="Magic value to determine how valuable the leverage is.");

#section server
	void onPlay(InfluenceCard@ card, Targets@ targets) const override {
		Object@ obj = arguments[0].fromConstTarget(targets).obj;
		Empire@ emp = obj.owner;
		if(emp !is null)
			emp.gainRandomLeverage(card.owner, arguments[1].decimal);
	}
#section all
};

//CostPerPlay(<Cost>, <Same Side> = True, <Same Empire> = False, <Match Targets> = False)
// Adds cost to playing a card relative to how many times cards of that type
// have been played before.
class CostPerPlay : InfluenceCardEffect {
	Document doc("Adds cost to play this card based on previous uses of the same type of card in this vote.");
	Argument addCost("Cost", AT_Decimal, doc="Cost added per prior use.");
	Argument sameSide("Same Side", AT_Boolean, "True", doc="Only count prior uses on the same side.");
	Argument sameEmp("Same Empire", AT_Boolean, "False", doc="Only count prior uses by the same empire.");
	Argument match("Match Targets", AT_Boolean, "False", doc="Only count prior uses against the same target.");

	int getPlayCost(const InfluenceCard@ card, const InfluenceVote@ vote, const Targets@ targets) const {
		if(vote is null)
			return 0;
		InfluenceCardSide matchSide = ICS_Both;
		Empire@ matchEmp;
		const Targets@ matchTargets;
		if(arguments[1].boolean)
			@matchEmp = card.owner;
		if(arguments[2].boolean && card.type.sideMode == ICS_Both && targets !is null)
			matchSide = targets[card.type.sideTarget].side ? ICS_Support : ICS_Oppose;
		if(arguments[3].boolean) {
			if(targets is null)
				@matchTargets = card.targets;
			else
				@matchTargets = targets;
		}
		uint count = vote.countPlayed(card.type, matchEmp, matchSide, matchTargets);
		return floor(double(count) * arguments[0].decimal);
	}
};