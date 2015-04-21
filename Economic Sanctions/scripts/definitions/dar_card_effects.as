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