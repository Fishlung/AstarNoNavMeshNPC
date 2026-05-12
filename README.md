# Overview
An adaptation of tib69's NoNavmeshNPC. The changes made were originally for a personal project, but unfortunately this NPC script no longer suits my needs. I decided I wanted to publish my changes anyway, so that anyone else who's interested in making a free-roaming NPC without using Navigation Meshes can perhaps learn from my mistakes. 

The NPC uses AStar for the bulk of its navigation, breaking away from the AStar map and directly chasing its target when it sees the player. If visual contact is lost, it attempts to return to the AStar map to continue following. While using AStar helps tremendously in helping it navigate around obstacles, the NPC still occasionally gets stuck against the wall. While I believe there are slight improvements from the original, this is still unfortunately something I haven't been able to fix. The NPC works best if it breaks away from the AStar map for only brief periods of time, and only in open areas with few obstacles to get stuck on. 

# Setup
Assign the NPC script to a CharacterBody3D node. Add the following nodes for full functionality:
- A front Raycast3D to detect obstaces
- A left and right Raycast3D for obstacle avoidance
- A line of sight Raycast3D to detect players

Optionally, edit the exported variables in the inspector to control speed, follow distance, acceleration, and other parameters. 

In another node, create your AStar3D map. Assign it to the NPC's astar_map exported variable. As long as the AStar map is properly configured, the NPC should now be able to navigate to the nearest point to its target.

# Final Notes
This version of the NPC is far more barebones than the repository it was forked from, as I stripped away a lot of the original functionality the original NPC had to better suit my needs. I highly recommend checking out the original project and figure out for yourself what suits your own needs. Additionally, I did my best to remove any parts I've added that aren't relevant to navigation, but there might be some left over that I wasn't able to catch. You can probably just ignore those. Or submit a pull request if it bothers you that much. I don't care. I'm not working on this anymore. 

Feel free to use this in your own projects, and adapt this in any way you'd like. On a comment under their [original post][post_link] on Reddit, the original creator wrote *"I share my knowledge and this npc system with anyone, I wanna make the godot community better with this way."* [(Source)][comment_link]. I extend the same sentiment, and I hope someone is able to find use out of this the same way I was able to.

[post_link]: https://www.reddit.com/r/godot/comments/1puoqgd/godot_terrain_npc_ai_without_navmesh/
[comment_link]: https://www.reddit.com/r/godot/comments/1puoqgd/comment/nvq3eq1/
