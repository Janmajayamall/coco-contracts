# COCO

Coco is like any other social networking site - you can create groups on topics of interest, join groups, post in groups, but with a twist. 
In Coco group feeds are moderated by community through challenges.

To post in group feed you need to sign message that says - "If anyone thinks that my post isn't fit for the group feed, then feel free to challenge me. Here's 0.05 WETH". Now if someone thinks that your post isn't suitable for group, they will challenge your post by putting in double that amount that you initially put in (i.e. 0.1 WETH). Challenges can be subsequently challenged by doubling the amount put in for the last challenge as long as challenge is made before challenge period expires. If a challenge remains unchallenged until after expiry of challenge period, the outcome favoured by challenge is declared as the final outcome for the post. After every successful challenge, challenge period renews. Once final outcome is declared, the challenger that favoured the final outcome wins the entire amount put in against them. 

If a post receives many consecutive challenges and crosses the threshold preset for challenge volume, it is escalated to moderation committee and no further challenges are allowed. Every group has a moderation committee that declares the final result of such posts. 

The effect of having moderation committee only interfere in posts that are "contentious" in nature is following - every challenger judges a post by what they think the committee would think about the post. This is how COCO scales moderation. Moderation committee only has to interfere in 1% of posts, while challenges by community takes care of rest. 

You can try COCO right now @ [https://cocoverse.club/](https://cocoverse.club/).

This repository contains solidity contracts for COCO that are deployed on Arbitrum L2. Source code for frontend can be found [here](https://github.com/Janmajayamall/coco-frontend) and backend can be found [here](https://github.com/Janmajayamall/coco-backend).
