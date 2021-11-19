## Tests consideration

1.

## Points to note

1. One could consecutively stake for the right outcome, once they spot someone staking on the wrong outcome so that they can get their stake.
   a. Thing to note here is that this is only possible if they are staking on the right outcome,
   which solves our purpose of extracting the right outcome.
   b. Anyone who does this is very sure of what the oracle would resolve to. In such a case,
   they could either be an insider or are really good.
   (i) If they are an insider, then overtime people will realise and abandon using the services of the oracle in question
   (ii) If they are really good; that's nice. It's fair, they are being rewarded for the risk.
   c. One -ve side effect of this is that it increases the frequency of intervention by oracle. But in
   my opinion, if it isn't insider trading then oracle can simply increase escalation limit to control frequency.
   d. Right now, oracle fee is only taken from the losing stake. It's possible to disincentivise such behaviour by
   taking oracle fee from the sum of both stakes. In my opinion, this will simply limit the number of times this can
   be done. So whenever the opposite stake (after deducting oracle fee) is greater than the amount deducted in oracle
   fees from the winning stake, this strategy is still profitable.
   Also, I would argue against imposing oracle fee on winning stake because of unecessary complications it accompanies.

2. Why oracle fee is only deducted from the losing stake? \
   It's simple. Winners don't lose anything & receive some share of the loser.
