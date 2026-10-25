pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- main

--for weitchin between dialog,
--boss, win and other schtuff
state = nil
function change_gamestate(new_state, cond)
	state = new_state
  if state == "boss" then
    boss_init()
  elseif state == "mainmenu" then
		mainmenu_init(cond)
	elseif state == "dialog" then
    dialog_init()
  end
end



function _init()
	poke( 0x5f2e, 1 ) -- enable hidden colors
--green is transperent so black can be used
 palt(11,true)
 palt(0,false)
 
 
 --i need more colors and
 --this aint a colorful game
 --so i just take out the
 --colors i aint gonna use
 pal(10, 129, 1)
 pal(14, 132, 1)
 pal(15,136, 1)
 pal(9,140, 1)
 pal(4,11,1)
 pal(5,10,1)


 change_gamestate("mainmenu", false)

 -- x,y is the top left corner
 -- of the player dude
 
end


--60fps feels better so i use that
function _update60()

 if not stat(57) then
   music(18) -- restart only if finished
 end
 if state == "boss" then
  boss_update()
 elseif state == "mainmenu" then
  mainmenu_update()
 elseif state == "dialog" then
  dialog_update()
 end
end

function _draw()
 cls(1)
 
 if state == "boss" then
  boss_draw()
 elseif state == "mainmenu" then
  mainmenu_draw()
 elseif state == "dialog" then
  dialog_draw()
 end
end
















-->8
-- player

-- how the player feels
walk_speed=1.5
jump_speed=-3.5
gravity=0.3
max_fall_speed=3
drop_frames=1

-- how high you bounce when
-- you hit the boss in the air
pogo_speed=-3

-- where the sprite 22/24 thing
-- is drawn from the player
offsetx=8
offsety=8

flipped=false




--combat varz

incombat = false

swinging = false
airSwinging = false

-- how long the ground sword
--stays out (60fps)
ground_swing_frames=15

-- how many frames at the start
-- and end does the ground swing
-- shows the textured sprite
sword_edge_frames=4

-- how far in front of the player
-- the ground sword is drawn
ground_sword_distance=10

swing_timer=0

-- the 4 corners of the air swing
-- the textured but fo teh sword rotates around to make
--the illuseion that the sword or pin is spinning
air_corners={
 {x=4,y=4,flip_x=false,flip_y=false},
 {x=0,y=4,flip_x=true,flip_y=false},
 {x=0,y=0,flip_x=true,flip_y=true},
 {x=4,y=0,flip_x=false,flip_y=true}
}





--anim


player_animations={
 idle={
  nil,--frames between update frames. nil for 1 frame shtuff
  1
 },
 running={
  5,
  1,2,3,4,5
 },
 jumping={
  nil,
  17
 },
 falling={
  nil,
  18
 },
 spinning={
  5,
  19,20
 },
 death={
  nil,
  21
 }
}

function player_init(sprite_x,sprite_y, isInCombatScenerio_AlsoHowLongCanIMakeThisVariableNameIThinkICanMakeItAsLongAsIWantWahahahaha)
 -- hitbox is 4x5, inside the
 -- 8x8 sprite
 local hitbox_x=sprite_x+2
 local hitbox_y=sprite_y+3

 player=create_body(hitbox_x,hitbox_y,4,5)
 player.spawn_x=hitbox_x
 player.spawn_y=hitbox_y

 -- state only picks the animation
 player.state="idle"
 player.anim_timer=0

 -- start with the sword put away
 swinging=false
 airSwinging=false
 swing_timer=0

 incombat = isInCombatScenerio_AlsoHowLongCanIMakeThisVariableNameIThinkICanMakeItAsLongAsIWantWahahahaha or false
end

function player_update()
 -- left and right
 local move_direction=0
 if btn(⬅️) then
  move_direction=-1
  flipped=true
 end
 if btn(➡️) then
  move_direction=1
  flipped=false
 end
 move_horizontal(player,move_direction*walk_speed)

 -- count down the drop timer
 if player.drop_timer>0 then
  player.drop_timer-=1
 end

 local attack_pressed=false

 if btnp(❎)then 
  if incombat == true then  
  	attack_pressed=true 
  end 
 end


 local jump_pressed=btnp(🅾️)

 local down_held=btn(⬇️)

 if jump_pressed and player.grounded then
  if down_held and standing_on_semisolid(player) then
   -- down + jump = fall through
   player.drop_timer=drop_frames
  else
   player.vy=jump_speed
  end
  player.grounded=false
 end

 -- gravity
 player.vy=min(player.vy+gravity,max_fall_speed)
 move_vertical(player)

 -- attack: sword comes out
 if attack_pressed then
  swinging=true
  if player.grounded then
   -- on the ground: sword stays
   -- out for a short time
   airSwinging=false
   swing_timer=ground_swing_frames
  else
   -- in the air: sword stays out
   -- until we land
   airSwinging=true
  end
 end

 -- put the sword away
 if swinging then
  if airSwinging then
   if player.grounded then
    swinging=false
    airSwinging=false
   end
  else
   swing_timer-=1
   if swing_timer<=0 then
    swinging=false
   end
  end
 end

 -- fell off the screen, respawn
 if player.y>128 then
  player.x=player.spawn_x
  player.y=player.spawn_y
  player.vy=0
 end

 update_player_state(move_direction!=0)
end

-- the state only picks the
-- animation, it never changes
-- how the player moves
function update_player_state(moving)
 local new_state="idle"

 if not player.grounded then
  if airSwinging then
   new_state="spinning"
  elseif player.vy<0 then
   new_state="jumping"
  else
   new_state="falling"
  end
 elseif moving then
  new_state="running"
 end

 if new_state==player.state then
  player.anim_timer+=1
 else
  player.state=new_state
  player.anim_timer=0
 end
end

-- which sprite to draw at hsis frame
function get_player_frame()
 local anim=player_animations[player.state]
 local delay=anim[1]

 -- no delay means only one frame
 if delay==nil then
  return anim[2]
 end

 local frame_count=#anim-1
 local step=flr(player.anim_timer/delay)
 return anim[2+step%frame_count]
end

-- the box the sword hurts stuff
-- with. gives x,y,w,h or nil
-- if the sword aint out
function get_sword_box()
 if not swinging then
  return nil
 end

 -- air sword: the 4 spinny
 -- sprites cover 20x20
 if airSwinging then
  return player.x-offsetx,player.y-offsety,20,20
 end

 -- ground sword: one 16x16
 -- sprite in front of the dude
 local sword_x=player.x-offsetx
 if flipped then
  sword_x-=ground_sword_distance
 else
  sword_x+=ground_sword_distance
 end
 return sword_x,player.y-offsety,16,16
end

function draw_air_sword()
 -- which corner the blade is in.
 -- it moves every time the spin
 -- animation steps to its next frame
 local spin_delay=player_animations.spinning[1]
 local blade_corner=flr(player.anim_timer/spin_delay)%4+1

 for i=1,4 do
  local corner=air_corners[i]

  -- blade corner gets sprite 24,
  -- the other corners get 22
  local sprite_number=22
  if i==blade_corner then
   sprite_number=24
  end

  spr(sprite_number,
   player.x-offsetx+corner.x,
   player.y-offsety+corner.y,
   2,2,
   corner.flip_x,corner.flip_y)
 end
end

function draw_ground_sword()
 -- push the sword away from the
 -- player, in the direction
 -- they are facing
 local sword_x=player.x-offsetx
 if flipped then
  sword_x-=ground_sword_distance
 else
  sword_x+=ground_sword_distance
 end
 local sword_y=player.y-offsety

 -- sprite 35 while the sword is
 -- coming in or going out,
 -- sprite 33 in the middle
 local frames_out=ground_swing_frames-swing_timer
 local sprite_number=33
 if frames_out<=sword_edge_frames or swing_timer<=sword_edge_frames then
  sprite_number=35
 end

 spr(sprite_number,sword_x,sword_y,2,2,flipped)
end

function player_draw()
 

 if swinging then
  if airSwinging then
   draw_air_sword()
  else
   draw_ground_sword()
  end
 end

 --draw the player sprite
 spr(get_player_frame(),player.x-2,player.y-3,1,1,flipped)

end







-->8
-- collision shtuff

-- sprite flags
solid_flag=0
semisolid_flag=1

-- one screen big map
map_tiles=16

-- which 16x16 chunk of the map
-- the collision reads from, in
-- tiles. each state sets this
-- when it starts
room_x=0
room_y=0

--makes a moveable entity thinfg fot he player
function create_body(x,y,width,height)
 local body={}
 body.x=x
 body.y=y
 body.w=width
 body.h=height
 body.vy=0
 body.grounded=false

 -- i already for got what htis does
 body.drop_timer=0
 return body
end

-- find if two boxes overlapping, use for hurtboxes and shii
function boxes_overlap(x1,y1,w1,h1,x2,y2,w2,h2)
 local overlap_x=x1<x2+w2 and x1+w1>x2
 local overlap_y=y1<y2+h2 and y1+h1>y2
 return overlap_x and overlap_y
end

-- is tile soliid

function is_solid_tile(tile_x,tile_y)
 if tile_x<0 or tile_x>=map_tiles then return true end
 if tile_y<0 then return true end
 if tile_y>=map_tiles then return false end

 local sprite_number=mget(tile_x+room_x,tile_y+room_y)
 return fget(sprite_number,solid_flag)
end

-- is tile semisolidd??
function is_semisolid_tile(tile_x,tile_y)
 if tile_x<0 or tile_x>=map_tiles then return false end
 if tile_y<0 or tile_y>=map_tiles then return false end

 local sprite_number=mget(tile_x+room_x,tile_y+room_y)
 local semisolid=fget(sprite_number,semisolid_flag)
 local solid=fget(sprite_number,solid_flag)
 return semisolid and not solid
end

-- si a box in a solid? not semisolid
function touching_solid(x,y,width,height)
 local left_tile=flr(x/8)
 local right_tile=flr((x+width-1)/8)
 local top_tile=flr(y/8)
 local bottom_tile=flr((y+height-1)/8)

 return is_solid_tile(left_tile,top_tile)
 or is_solid_tile(right_tile,top_tile)
 or is_solid_tile(left_tile,bottom_tile)
 or is_solid_tile(right_tile,bottom_tile)
end

-- would the body be inside a
-- solid tile if it moved movex ore movye
function would_collide(body,move_x,move_y)
 return touching_solid(body.x+move_x,body.y+move_y,body.w,body.h)
end

-- is the player standing on a semisolid
function standing_on_semisolid(body)
 local row_below=flr((body.y+body.h)/8)
 local left_tile=flr(body.x/8)
 local right_tile=flr((body.x+body.w-1)/8)

 local on_solid=is_solid_tile(left_tile,row_below)
  or is_solid_tile(right_tile,row_below)
 if on_solid then return false end

 return is_semisolid_tile(left_tile,row_below)
  or is_semisolid_tile(right_tile,row_below)
end

-- would moving down by a little
-- put the body on a semisold?
-- this only happens when its buttt
-- crossess into a new tile row, so
-- you can still jump up through
-- platforms from below.
function will_land_on_semisolid(body,step)
 -- was gonna ignore platforms while dropping but i changed it
 if body.drop_timer>0 then return false end

 local feet_row_now=flr((body.y+body.h-1)/8)
 local feet_row_next=flr((body.y+step+body.h-1)/8)

 -- still in the same row
 if feet_row_next<=feet_row_now then return false end

 local left_tile=flr(body.x/8)
 local right_tile=flr((body.x+body.w-1)/8)
 return is_semisolid_tile(left_tile,feet_row_next)
  or is_semisolid_tile(right_tile,feet_row_next)
end

-- move horizzontallt at most one
-- pixel at a time so we never
-- tp thorugh a wall
function move_horizontal(body,amount)
 local distance_left=abs(amount)
 local direction=sgn(amount)

 while distance_left>0 do
  -- move less than 1 pixel if
  -- there is less than 1 left
  local step=min(1,distance_left)*direction

  if would_collide(body,step,0) then
   return true
  end
  body.x+=step
  distance_left-=1
 end

 return false
end

-- move up or down using body.vy.
-- sets body.grounded when we land
-- on something. returns true if
-- we hit something.
function move_vertical(body)
 local distance_left=abs(body.vy)
 local direction=sgn(body.vy)
 body.grounded=false

 while distance_left>0 do
  local step=min(1,distance_left)*direction

  local hit_solid=would_collide(body,0,step)
  local hit_platform=direction>0 and will_land_on_semisolid(body,step)

  if hit_solid or hit_platform then
   -- moving down means we landed
   if direction>0 then
    body.grounded=true
   end
   body.vy=0
   return true
  end

  body.y+=step
  distance_left-=1
 end

 return false
end

-- pull the body down, using the
-- gravity and max_fall_speed
-- numbers from playerr
function apply_gravity(body)
 body.vy=min(body.vy+gravity,max_fall_speed)
end

-->8
--boss entity
--bbos because im 90% sure
--that boss is used by the
--boss state but i dont want
--to check but i am procrastinationinging
--by writing this patagraph instesad
--and watching youtube


--i aint commenting allese vars bro
animTimerBossThreshold = 60

animTimerBoss = 0
bossSpr = 26

bullet_speed=1.5

bullet_life=100

time_between_attacks=90

warning_frames=40


attack_names={"left","right","top","bottom","aimed"}


aimed_x=80
aimed_y=116
aimed_speed=1.2
aimed_shots=3

aimed_gap=25

aimed_life=120


boss_bullets={}

attack_timer=0
warning_timer=0
next_attack="left"
next_start=0


aimed_left=0
aimed_timer=0

function bboss_init()
 -- clear everything so
 -- a reset starts fresh
 boss_bullets={}
 attack_timer=time_between_attacks
 warning_timer=0
 aimed_left=0
end

function spawn_bullet(x,y,vx,vy,life)
 add(boss_bullets,{
  posx=x,
  posy=y,
  velx=vx,
  vely=vy,
  lifetime=life
 })
end

--move all boolets
function update_bullets()
 for b in all(boss_bullets) do
  b.posx+=b.velx
  b.posy+=b.vely
  b.lifetime-=1
  if b.lifetime<=0 then
   del(boss_bullets,b)
  end
 end
end

function draw_bullets()
 for b in all(boss_bullets) do
  spr(11,b.posx,b.posy)
 end
end

-- ullet hitbox is the 4x4
--in the midkle of the sprite
--true if player touchin any boolet
function player_hit_by_bullet()
 for b in all(boss_bullets) do
  if boxes_overlap(
   player.x,player.y,player.w,player.h,
   b.posx+2,b.posy+2,4,4) then
   return true
  end
 end
 return false
end

-- pick the next attack and
-- start the warning
function pick_attack()
 next_attack=rnd(attack_names)

 --walls go where the player is
 --the covered part is centered
 --on you, so you gotta move
 --side are 6 tal
 --vert are 8 wide
 --mid() keeps it on screen
 if next_attack=="left" or next_attack=="right" then
  next_start=flr((player.y+2-24)/8)-3
  next_start=mid(0,next_start,6)
 elseif next_attack=="top" or next_attack=="bottom" then
  next_start=flr((player.x+2)/8)-4
  next_start=mid(0,next_start,8)
 end

 warning_timer=warning_frames
end

-- warning done, nwo shoot stuff
function fire_attack()
 local a=next_attack

 if a=="aimed" then
  --the shots come out one
  --by one in bboss_update
  aimed_left=aimed_shots
  aimed_timer=0
 elseif a=="left" or a=="right" then
  --6 bullets in a column
  --bos area is y=24 to 120
  for i=0,5 do
   local y=24+(next_start+i)*8
   if a=="left" then
    spawn_bullet(-8,y,bullet_speed,0,bullet_life)
   else
    spawn_bullet(128,y,-bullet_speed,0,bullet_life)
   end
  end
 else
  --8 bullets in a row
  for i=0,7 do
   local x=(next_start+i)*8
   if a=="top" then
    spawn_bullet(x,-8,0,bullet_speed,bullet_life)
   else
    spawn_bullet(x,128,0,-bullet_speed,bullet_life)
   end
  end
 end

 attack_timer=time_between_attacks
end


--shoot towards the player
function shoot_aimed()
 local dx=(player.x+2)-aimed_x
 local dy=(player.y+2)-aimed_y
 local dist=max(sqrt(dx*dx+dy*dy),1)

 --dividing by dist makes the
 --direction 1 long then we
 --times it by the speed
 local vx=dx/dist*aimed_speed
 local vy=dy/dist*aimed_speed

 ---4 because the bullet
 --is 8x8 nd we want its
 --middle on aimed_x,aimed_y
 spawn_bullet(aimed_x-4,aimed_y-4,vx,vy,aimed_life)
end

function bboss_update()
  animTimerBoss += 1
  if animTimerBoss >= animTimerBossThreshold then
    animTimerBoss = 0
    if bossSpr == 26 then
      bossSpr = 90
    else
      bossSpr = 26
    end
  end

  if warning_timer>0 then
   --warning is blinkin
   warning_timer-=1
   if warning_timer==0 then
    fire_attack()
   end
  else
   --resting between attaccks
   attack_timer-=1
   if attack_timer<=0 then
    pick_attack()
   end
  end

  --homing alarm shots
  if aimed_left>0 then
   aimed_timer-=1
   if aimed_timer<=0 then
    shoot_aimed()
    aimed_left-=1
    aimed_timer=aimed_gap
   end
  end

  update_bullets()
end

--blinkin red counter as a 
--warning
function draw_warning()
 if warning_timer<=0 then return end
--onn for 4 frames off for 4
 if warning_timer%8>=4 then return end

 local a=next_attack
 if a=="left" then
  rectfill(0,24+next_start*8,3,24+(next_start+6)*8-1,8)
 elseif a=="right" then
  rectfill(124,24+next_start*8,127,24+(next_start+6)*8-1,8)
 elseif a=="aimed" then
  -- line from the gun to you
  line(aimed_x,aimed_y,player.x+2,player.y+2,8)
 elseif a=="top" then
  rectfill(next_start*8,0,(next_start+8)*8-1,3,8)
 else
  rectfill(next_start*8,124,(next_start+8)*8-1,127,8)
 end
end

function bboss_draw()
	spr(53,94,96,4,3)
 spr(bossSpr, 87, 85, 4, 4)
 draw_warning()
 draw_bullets()
end





-->8
--state dialoug
dialogs = {
  "hey lil' man! how you doing?!",
  "by the way have you seen jim?",
  "he didnt clock in today.",
  "im getting kinda worried.",
  "youknow, for the meeting",
  "where he presents the thing",
  "he didnt even call ahead of time",
  "hmmm...",
  "...",
  "he mustive overslept",
  "heyyy",
  "can you do me a quick favor?",
  "please head overto hisplace and-",
  "wake him up so that we can-",
  "start this veryimportant meeting",
  "...",
  "...!",
  "fine il give you Abonus if you-",
  "do this for me.",
  "ok good",
  "take this pillow and-",
  "smack him with it. ",
  "(use the ❎ button to swing it)",
  "i know hes big so be careful-",
  "not to get hit or you mightget-",
  "seriously hurt!",
  "ok bye!!!!!"
}

current_dialog = 1

function advance_dialog()
  current_dialog +=1
  if current_dialog>#dialogs then
    change_gamestate("boss")
  end
end

function dialog_init()
  -- the dialog room is the chunk
  -- below the boss room
  room_x=0
  room_y=16
  -- start the dialog over so
  -- playing again doesnt crash
  current_dialog=1
  player_init(64,64, false)
  flipped = true
end

function dialog_update()
  if btnp(🅾️)then
    advance_dialog()
  end
  player_update()
end

function dialog_draw()
  map(0,16,0,0,16,16)

  player_draw()

  print("\^o2ff\f8press 🅾️ to continue the dialog", 2, 16, 2)

  print("\^o2ff\f8"..dialogs[current_dialog], 0, 96, 2)
  

end
-->8
--state boss

--how sleepy jim is
boss_start_hp=100

death_frames=15

wipe_speed=12

--so jim aint just dying fro m on hit
--(invinc frames)
boss_hit_cooldown=20

boss_hp=boss_start_hp
boss_hit_timer=0

--what the boss scene is doin
--"play" normal fightin
--"dying" meansd frozen
--"wipe" emans sceen wipinf
boss_mode="play"
death_timer=0
wipe_pos=0

function boss_init()
	--the boss room is the top
	--left chunk of the map
	room_x=0
	room_y=0
	boss_hp=boss_start_hp
	boss_hit_timer=0
	boss_mode="play"
	death_timer=0
	wipe_pos=0
	player_init(16,96, true)
	bboss_init()
end

--jimy hurtbox is
--x=96,y=96 to x=128,y=120
--
function check_sword_hit()
 if boss_hit_timer>0 then
  boss_hit_timer-=1
 end

 local sx,sy,sw,sh=get_sword_box()
 if sx==nil or boss_hit_timer>0 then
  return
 end

 if boxes_overlap(sx,sy,sw,sh,96,96,32,24) then
  boss_hit_timer=boss_hit_cooldown

  if player.grounded then
   boss_hp-=8
  else
   -- midair does 1 damage but
   -- you bounce off him (pogo)
   boss_hp-=3
   player.vy=pogo_speed
  end

  if boss_hp<=0 then
   change_gamestate("mainmenu",true)
  end
 end
end

function hurt_player()
 boss_mode="dying"
 death_timer=death_frames
 player.state="death"
 player.anim_timer=0
 swinging=false
 airSwinging=false
end

function boss_update()
 if boss_mode=="play" then
  player_update()
  bboss_update()

  check_sword_hit()
  --jim might have just lost
  --o make sure were still
  --in the boss state
  if state!="boss" then
   return
  end

  if player_hit_by_bullet() then
   hurt_player()
  end

 elseif boss_mode=="dying" then
  --everything freezes and the red
  --spritre   guy shows
  death_timer-=1
  if death_timer<=0 then
   boss_mode="wipe"
   wipe_pos=0
  end

 elseif boss_mode=="wipe" then
  wipe_pos+=wipe_speed

--resest the fight
  if wipe_pos>=300 then
   change_gamestate("boss")
  end
 end
end

--do the wipe
function draw_wipe()
 if boss_mode!="wipe" then
  return
 end
 for y=0,127 do
  local x=wipe_pos-y
  if x>=0 then
   rectfill(0,y,x,y,0)
  end
 end
end

function boss_draw()
 map(0,0,0,0,16,16)

 
 bboss_draw()

 print("\^o2ff\f8jimmy's sleepyness: "..boss_hp.."%", 8, 8, 2)

 player_draw()

 draw_wipe()
end

-->8
--state mainmenu

wincol=0

jimpos = 250

function mainmenu_init(won)
  if won then
    wincol = 5
    jimpos = 0
  end
end

textcol = 6
playersprr = 14
jimsbr = 1

mainmenubuttonthreshold = 15
mainmenubuttontimer = 0



function mainmenu_update()
    mainmenubuttontimer += 1

    if mainmenubuttontimer >= mainmenubuttonthreshold then
        mainmenubuttontimer = 0

        if textcol == 7 then
            textcol = 6
            playersprr = 14
        else
            textcol = 7
            playersprr = 15

        end
    end
    if btnp(🅾️) then
      change_gamestate("dialog")
    end
end

function mainmenu_draw()
	cls(0)

	spr(64, 48, 4, 4, 4)
 spr(playersprr,60,60)
 
 print("press 🅾️ to start!!", 32, 88, textcol)
 print("you won!!!!!", 44, 96, wincol)
 print("you got paid $10000000", 22, 104, wincol)
 print("for a reward",44, 112, wincol)
 print("no cap bro trust",36,120, wincol)
 

end

__gfx__
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000dddddddddddddddd00000110a0a0a0a0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000bbbbbbbbbbbbbbbbbbb777bbbbb777bbbbbbbbbb000000001111111111111111000000000a07770abb8888bbb00000000000bbbbbbbbbbbbbbbbbbbb
00700700bbb777bbbbb777bbbb7770bbbb7770bbbbb777bb00000000000000000000000001110000a07770a0b877778b000000000000000bbbb888bbbbb888bb
00077000bb7770bbbb7770bbbb7077bbbb7077bbbb7770bb0000000001100011bbbbbbbb000000000a70770ab877778b088800088808880bbb8882bbbb8882bb
00077000bb7077bbbb7077bbbb7777bbbb7777bbbb7077bb0000000000000000bbbbbbbb11000110a077eed0b877778b0808080808080800bb8288bbbb8288bb
00700700bb7777bbbb7777bbbb77776bb77777bbbb7777bb0000000000001110bbbbbbbb000000000a7eeeeab877778b0888000808080800bb8888bbbb8888bb
00000000bb7777bbbb77776bb7bbbbbbbbbbbb6bb77777bb0000000000000000bbbbbbbb11111111a07777a0bb8888bb0008080888088800bb88882bb88888bb
00000000bb7bb6bbbb7bbbbbbbbbbbbbbbbbbbbbbbbbb6bb0000000001100000bbbbbbbbdddddddd0a7a060abbbbbbbb0000000000000000bb8bbbbbbbbbb2bb
a0a0a0a0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbddddbbbbbb
0a0a0a0abbb777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdd7777ddbbbb
a0a0a0a0bb7770bbbbb777bbbbb6bbbbbbb7bbbbbbb888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbd7d77d7dbbbb
0a0a0a0abb7077bbbb7777bbbb7777bbbb7077bbbb8882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777bbbbbbbbbbbbbbbbbbbbbd77d77d77dbbb
a0a0a0a0bb7777bbbb7070bbbb77707bbb77776bbb8288bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb70007bbbbbbbbbbbbbbbbbbbbd77777777dbbb
0a0a0a0ab777776bb777776bb70777bbb67777bbbb8888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7707bbb777bbbbbbbbbbbbbbd7d7777d7dbbb
a0a0a0a0bbbbbbbbbbbbbbbbbb7777bbbb7707bbbb8888bbbbbbbbbbbbbbb777bbbbbbbbbbbbbd7dbbbbb777bbb707bbb70007bbbbbbbbbbbbbbd6dddd6dbbbb
0a0a0a0abbbbbbbbbbbbbbbbbbbb6bbbbbbb7bbbbb8bb2bbbbbbbbbbbbbbb777bbbbbbbbbbbbb7d7bbbb7000797077bbbb7707bbbbbbbbbbddbbdd7777ddbbdd
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbb777bbbbbbbbbbbbbd7dbbbb97707970007bbb707bbbbbbbbbbbddbbd7dddd7dbbdd
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbb777bbbbbbbbbbbbbd7dbbbb99707ccc7779997077bbbbbbbbbbbbbdbd777777dbdbb
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbb777bbbbbbbbbbbbb7d7bbb997077cccccccc970007bbbbbbbbbbbbdd77777777ddbb
00000000bb7777bbbbbbbbbbbb7d7dbbbbbbbbbb00000000bbbbbbbbbbb777bbbbbbbbbbbbb7d7bbbb9970007ccccccc9977799bbbbbbbbbbbbd77777777dbbb
00000000b77777777bbbbbbbb7d7d7d7dbbbbbbb00000000bbbbbbbbb77777bbbbbbbbbbbd7d7dbbb999c777cccccc99999999999bbbbbbbbbbd77777777dbbb
00000000bbbb7777777bbbbbbbbb7d7d7d7bbbbb00000000bbbbbb7777777bbbbbbbbbd7d7d7dbbbb99ccccccccc99999bb999999dddddbbbbbd77777777dbbb
00000000bbbbbbbb77777bbbbbbbbbbbd7d7dbbb00000000bbbbbb77777bbbbbbbbbbb7d7d7bbbbb999ccccccc9999999bbbbb99dddddddbbbbd77777777dbbb
00000000bbbbbbbbbb77777bbbbbbbbbbb7d7d7b00000000bbbbbb777bbbbbbbbbbbbbd7dbbbbbbb99cccc999999999dddbbbbbbdd777ddbbbbd77777777dbbb
00000000bbbbbbbbbbbb7777bbbbbbbbbbbbd7d7bbbbbddddddddbbbbbbddddddbbbbbbb000000009999999999977700ddbbbbbbdd777ddbbbbd77777777dbbb
00000000bbbbbbbbbbbb7777bbbbbbbbbbbb7d7dbbbddd666666ddddddd66d666dddbbbb000000009999999777770077ddbbbbbbdd777ddbbbbbd777777dbbbb
00000000bbbbbbbbbb77777bbbbbbbbbbbd7d7dbbbdd66d66666d6666666d666666ddbbb000000009997777777707777ddbbbbbbdddddddbbbbbd777777dbbbb
00000000bbbbbbbb77777bbbbbbbbbbb7d7d7bbbbbd666dd6666dd66666d6666666ddbbb00000000dd77770007777777ddbbbbbbbdddddbbbbbbbd7777dbbbbb
00000000bbbb7777777bbbbbbbbbd7d7d7dbbbbbbbd6666d66666d66666d6666666dddbb00000000dd70007777777777ddbbbbbbbbbbbbbbbbbbbddddddbbbbb
00000000b77777777bbbbbbbbd7d7d7d7bbbbbbbbdd6666dd6666d6666d66666666d6ddb00000000dd77777777777777ddbbbbbbbbbbbbbbbbbbbdbbbbdbbbbb
00000000bb7777bbbbbbbbbbbbd7d7bbbbbbbbbbbd666666d66666d666d66666666d66db00000000dd77777777777777ddbbbbbbbbbbbbbbbbbbbdbbbbdbbbbb
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbd666666d66666dd66d66666666d66dd00000000ddd777077007707dddbbbbbbbbbbbbbbbbbdddbbbbdddbbb
bbbbbbbbbdddbbbbbbbbbbbbbbbbbbbb00000000bdd66666d666666d66d66666666d666dbbbbbbbbbdd777700770077ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
dddddddddd7dddddddddddddddddddbb0000000066dd6666d666666d66d66666666d666dbbbbbbbbbddd7777777777dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
d77d77d77d7dd7777dd7dd7dd7dd7dbb00000000666d6666d666666d66d66666666d666dbbbbbbbbbbddd77777777dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
d77dddd77dddd7777dd7dd7dd7dd7dbb00000000666dd6666d66666d66d66666666d66ddbbbbbbbbbbbdddd7777ddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
d77d77d77dbbd77dddd7dd7dd7dd7dbb000000006666dd666d66666d666d6666666d66ddbbbbbbbbbbbbddddddddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
d77d77d77dbbd77dd7d7777dd7777dbb0000000066666d666d66666d666d6666666d666dbbbbbbbbbbbbbbddddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
d77d77d77dbbd77777d7777ddd77ddbb0000000066666dd66d66666d666d6666666d666dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
d77d77d77dbbdd7777d7777ddd77dbbb00000000b66666d66d66666d666d6666666d666dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ddddddddddbbbddddddddddddd7ddbbb00000000b66666d66d66666d666d6666666d666dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbdddbbbb00000000bb6666d66d66666d666d66666666d66dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbb3333333333333bbbbbbbbb00000000bb6666d6d666666d6666d6666666d66dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbb3444344334433bbbbbbbbb00000000bbb666d6d666666d6666d6666666d66dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbb3434343434343bbbbbbbbb00000000bbbbb6d6d66666d66666d66666666d6dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbb3444343434343bbbbbbbbb00000000bbbbbbd6d66666d66666d66666666d6dbbbbbbbbbbbbbb777999bbbbbbbb777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbb3434343434343bbbbbbbbb00000000bbbbbbdd66666d666666d66666666dddbbbbbbbbbbbbb70007999999bbb70007bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbb3434343434443bbbbbbbbb00000000bbbbbdddddddddddddddddddddddddddbbbbbbbbbbbb997707ccc77799997707bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbb3333333333333bbbbbbbbb00000000bbddddddddddddddbbbbdbbbbbbbbbddbbbbbbbbbbb999707ccc70007999707bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb997077cccc77079970779bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbb22222b22222bbbbbbbb22bbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb99970007ccc7079997000799bbbbbbbbbbbbbbbbbbbbbb
bbbbbb28822b288822bb2222222222bb00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb99cc777ccc707799bb777999dddddbbbbbbbbbbbbbbbbb
bbbbbb28882b288822b222228888222200000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb999ccccccc9700079bbbbb99dddddddbbbbbbbbbbbbbbbb
bbbbbb28882b2222222288888888882200000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb99cccc999999777dddbbbbbbdd777ddbbbbbbbbbbbbbbbb
bbbbbb28882b2882228888888888888200000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9999999999977700ddbbbbbbdd777ddbbbbbbbbbbbbbbbb
bbbbbb2888222882228882888228888200000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9999999777770077ddbbbbbbdd777ddbbbbbbbbbbbbbbbb
bbbbbb2888228888228882888222888266666666666666666666666666666666bbbbbbbbbbbbbbbbb9997777777707777ddbbbbbbdddddddbbbbbbbbbbbbbbbb
bbbbbb288222888828882288822288826dddddddddddddddddddddddddddddd6bbbbbbbbbbbbbbbbbdd77770007777777ddbbbbbbbdddddbbbbbbbbbbbbbbbbb
bbbb22288222888228882288822288826d6666666666666666666666666666d6bbbbbbbbbbbbbbbbbdd70007777777777ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb2228888228888228882288822222226d6ddd6ddd66dd66dd6d666ddd6666d6bbbbbbbbbbbbbbbbbdd77777777777777ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb288888882888822888222882bbb22b6d6d6d66d66d666d666d666d666666d6bbbbbbbbbbbbbbbbbdd77777700007777ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb288888822888222222222282bbb2bb6d6dd666d66d666d666d666dd66666d6bbbbbbbbbbbbbbbbbddd777700000077dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb2222882222822bbbbbbb2222bbbbbb6d6d6d66d66d6d6d6d6d666d666666d6bbbbbbbbbbbbbbbbbbdd777770000777ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb2b222bbb222bbbbbbbbbbbbbbbbbb6d6ddd6ddd6ddd6ddd6ddd6ddd6666d6bbbbbbbbbbbbbbbbbbddd7777777777dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000006d6666666666666666666666666666d60000000000000000bbbddd77777777dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000006d66666666666d6666666666666666d60000000000000000bbbbdddd7777ddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000006d6dd66d6666666d666dd666666666d60000000000000000bbbbbddddddddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000006d6d66d6d6666d6dd66d6666666666d60000000000000000bbbbbbbddddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000006d6dd66d66d66d6d6d6dd6d6666666d60000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000006d6666666d66666666666666666666d60000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000006dddddddddddddddddddddddddddddd60000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000000000000000000000000000666666666666666666666666666666660000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111118800000000000000000000005555000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111118800000000000000000000555550000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111188800000000000000000055555000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111188000000000000000000555500000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111188000000000000000055550000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111188000000000000005555500000000000
111111111111111111111111111111111111111111111111111111111111ddd11111111111111111111111111111111888000000000000555550000000000000
111111111111111111111111111111111111111111111111111dddddddddd7ddddddddddddddddddd11111111111111880000000000005555000000000000000
111111111111111111111111111111111111111111111111111d77d77d77d7dd7777dd7dd7dd7dd7d11111111111111880000000000005500000000000000000
111111111111111111111111111111111111111111111111111d77dddd77dddd7777dd7dd7dd7dd7d11111111111111880000000000005500000000000000000
111111111111111111111111111111111111111111111111111d77d77d77d11d77dddd7dd7dd7dd7d11111111111111880000000000055500000000000000000
111111111111111111111111111111111111111111111111111d77d77d77d11d77dddd7777dd7777d11111111111118880000000000055000000000000000000
111111111111111111111111111111111111111111111111111d77d77d77d11d77777d7777ddd77dd11111111111118800000000000055000000000000000000
111111111111111111111111111111111111111111111111111d77d77d77d11ddd777d7777ddd77d111111111111118800000000000055000000000000000000
111111111111111111111111111111111111111111111111111dddddddddd1111dddddddddddd7dd111111111111118800000000000555000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111ddd1111111111111118800000000000550000000000000000000
11111111111111111111111111111111111111111111111111111333333333333311111111111111111111111111188800000000000550000000000000000000
111111111111111111111111111111111111111111111111111113bbb3bb33bb3311111111111111111111111111188000000000000550000000000000000000
111111111111111111111111111111111111111111111111111113b3b3b3b3b3b311111111111111111111111111188000000000005550000000000000000000
111111111111111111111111111111111111111111111111111113bbb3b3b3b3b311111111111111111111111112228000000000005500000000000000000000
111111111111111111111111111111111111111111111111111113b3b3b3b3b3b311111111111111122222222122222200000000005500000000000000000000
111111111111111111111111111111111111111111111111111113b3b3b3b3bbb311111111111112222222222222222222000000005500000000000000000000
11111111111111111111111222221111111111111111111111111333333333333311122222222122222222222222222222200000055500000000000000000000
11111111111111111111222222222221111111122211111111111111111111111111222222222222222288822222222222220000055000000000000000000000
11111111111111111112222222222222111112222222111111111111111111111112222888822222222888882222228822220000055000000000000000000000
11111111111111111112288888882222211122222222211111111111111111111112228888882222222888882222288882220000055000000000000000000000
11111111111111111122888888888222221222288822221122222222222221122222228888882222222888822222288882222000555000000000000000000000
11111111111111111122888888888822222222888882222222222222222222222222228888882222222288222222288882222222550000000000000000000000
11111111111111111122888888888822222222888882222222288882222222222222228888882222222222222222288882222222550000000000000000000000
11111111111111111222888822888822222222888882222228888888882222222222222888822222222222222222288882222222220000000000000000000000
11111111111111111222888822888882222222288822222288888888888222222222222222222222222222222222288882222222222200000000000000000000
11111111111111111228888822888882222222222222222888888888888222222222222222222222222288222222288888888222222220000000000000000000
11111111111111111228888822288882222222222222288888888888882222222222222222882222222888822222288888888822222222000000000000000000
11111111111111112228888222288882222222222222888888822222222222222222222228888222222888822222288888888882882222000000000000000000
11111111111111112228888888888882222222288228888888222222222222222222222228888822222888822222288888888888888222200000000000000000
11111111111111112228888888888882222222888828888882222222222222222222222228888822222888822222288888888888888222200000000000000000
11111111111111112228888888888822222222888828888222288888822222222222222222888822222888822222288888888888888822220000000000000000
11111111111111122228888888888222222222888828888222888888882222222222222222888822222888822222288888828888888822220000000000000000
11111111111111122228888888888222222222888828888222888888882222222222222222888822222888822222288888828888888822222000000000000000
11111111111111122228888888888822222222888828888222288888888222222222222222888822222888822222288888828888888882222000000000000000
11111111111111122228888228888882222222888828888222222288888222222222222222888822222888822222288888828888888882222200000000000000
11111111111111122228888222888882222222888828888822222228888222222222222228888822222888822222288888222888888888222200000000000000
11111111111111122228888222288882222222888828888822222228888822222222222228888822222888822222288888222888888888222220000000000000
11111111111111122228888222288882222222888822888882222228888822222222222288888222222888822222888888222888828888822220000000000000
11111111111111122228888222288882222222888822888888822228888822222222882888882222222888822222888888222288228888822222000000000000
11111111111111112228888222888882222222888822288888882228888822222228888888882222222888822222888888222222222888822222200000000000
11111111111111112228888888888882222222888822228888888888888222222228888888822222222888822222888888222222222888882222200000000000
11111111111111112222888888888822222222888822222888888888888222222228888888222222222888822222888882222222222288888222220000000000
11111111111111111222888888888222222222888822222228888888882222222222888888222222222888822222888882222222222288888222222000000000
11111111111111111222288888882222222222888822222222288888822222122222288882222212222288222222888882222222222228888822222200000000
11111111111111111122222222222222222222288222222222222222222221122222222222222111222222222222888882222222222228888882222200000000
11111111111111111112222222222222222222222221112222222222221111112222222222221111122222222222288822222222222222888882222200000000
11111111111111111111122222222222222212222211111112222222211111111111112222111111112222222222222222220000222222288882222200000000
11111111111111111111111111111122222111222111111111222111111111111111111111111111111122222222222222000000000222228882222200000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111118880222222220000000000552222222222200000000
11111111111111111111111111111111111111111188881111111111111111111111111111111111111118800000000000000000000550222222222000000000
11111111111111111111111111111111111111888888881111111111111111111111111111111111111118800000000000000000000550000222220000000000
11111111111111111111111111111111118888888880888111111111111111111111111111111111111118800000000000000000000550000000000000000000
11111111111111111111111111111888888888800000088111111111111111111111111111111111111188800000000000000000000550000000000000000000
11111111111111111111111118888888888000000000088111111111111111111111111111111111111188000000000000000000005500000000000000000000
11111111111111111111888888888800000000000000088811111111111111111111111111111111111188000000000000000000055500000000000000000000
11111111111111118888888888000000000000000000008811111111111111111111111111111111111188000000000000000000055000000000000000000000
11111111111188888888800000000000000000000000008811111111111111111111111111111111111188000000000000000000055500000000000000000000
11111111188888888000000000077700000000000000008881111111111111111111111111111111111888000000000000000000005500000000000000000000
11111111188880000000000000777777000000000000000881111111111111111111111111111111111880000000000000000000005500000000000000000000
11111111188000000000000007777777770000000000000881111111111111111111111111111111111880000000000000000000005550000000000000000000
11111111188000000000000077777777777700000000000888111111111111111111111111111111111880000000000000000000000550000000000000000000
11111111188000000000000077777777777777000000000088111111111111111111111111111111111888000000000000000000000550000000000000000000
11111111888000000000000777777777777777770000000088111111111111111111111111111111111188000000000000000000000550000000000000000000
11111111880000000000007777777777777777777700000088811111111111111111111111111111111188000000000000000000000555000000000000000000
11111111880000000000077777777777777777777777000008811111111111111111111111111111111188000000000000000000000055000000000000000000
11111111880000000000777777777777777777777777000008811111111111111111111111111111111188800000000000000000000055000000000000000000
11111111880000000007777777777777777777777777000008881111111111111111111111111111111118800000000000000000000055500000000000000000
11111111880000000077777777777777777777777777000000881111111111111111111111111111111118800000000000000000000005500000000000000000
11111111880000000077777777777777777777777777000000881111111111111111111111111111111118880000000000000000000005500000000000000000
11111111880000000777777777777777777777777777000000888111111111111111111111111111111111880000000000000000000005550000000000000000
11111118880000007777777700007777777777777777000000088111111111111111111111111111111111880000000000000000000000550000000000000000
11111118800000077777777000770777777777000077000000088811111111111111111111111111111111880000000000000000000000550000000000000000
11111118800000077777770007770077777770007707700000008811111111111111111111111111111111888000000000000000000000550000000000000000
11111118800000077777770000700077777700077700700000008811111111111111111111111111111111188000000000000000000000555000000000000000
11111118800000077777770000000077777700007000700000008881111111111111111118888111111111188000000000000000000000055000000000000000
11111118800000077777770000000077777700000000700000000881111188111188111188888888111111188000000000000000000000055000000000000000
11111118800000007777777000000777777700000000700000000881111188811888111188818888111111188800000000000000000000055500000000000000
11111118800000007777777700007777777770000007700000000888111118811881111118881111111111118800000000000000000000005500000000000000
11111188800000007777777777777777777777000077700000000088111118888881111111888111111111118800000000000000000000005550000000000000
11111188000000007777777777777777777777777777700000000088111111888811111111188811111111118880000000000000000000000550000000000000
11111188000000007777777777777777777777777777700000000088811111888811111111888811111111111880000000000000000000000550000000000000
11111188000000007777777777777777777777777777700000000008811111188111111188888111111111111880000000000000000000000555000000000000
11111188000000007777777777777777777777777777000000000008811111111111111188811111111111111880000000000000000000000055000000000000
11111188000000007777777777777777777777777777000000000008881111111111111111111111111111111888000000000000000000000055500000000000
11111188000000000777777777777776666666677777000000000000881111111111111111111111111111111188000000000000000000000005550000000000
11111188000000000777777777666666666666677777000000000000881111111111111111111111111111111188000000000000000000000000550000000000
11111188000000000777777777666666666667777770000000000000888111111111111111111111111111111188800000000000000000000000555000000000
11111888000000000777777777766666666667777770000000000000088111111111111111111111111111111118800000000000000000000000055500000000
11111880000000000777777777777666667777777770000000000000088111111111111111111111111111111118800000000000000000000000005550000000
11111880000000000777777777777777777777777770000000000000088811111111111111111111111111111118800000000000000000000000000550000000
11111880000000000777777777777777777777777770000000000000008811111111111111111111111111111118880000000000000000000000000555000000
11111880000000000777777777777777777777777700000000000000008811111111111111111111111111111111880000000000000000000000000055500000
11111880000000000077777777777777777777777700000000000000088811111111111111111111111111111111880000000000000000000000000005500000
11111880000000000077777777777777777777777700000000000000088111111111111111111111111111111111880000000000000000000000000005550000
11111880000000000077777777777777777777777700000000000000888111111111111111111111111111111111888000000000000000000000000000555000
11118880000000000077777777777777777777777000000000000000881111111111111111111111111111111111188000000000000000000000000000055000
11118800000000000000777777777777777777777000000000000008881111111111111111111111111111111111188000000000000000000000000000055500
11118800000000000000770777777777777777777000000000000008811111111111111111111111111111111111188800000000000000000000000000005550
11118800000000000000770000777777777777777000000000000008811111111111111111111111111111111111118800000000000000000000000000000555
11118800000000000007770000000077777777770000000000000088811111111111111111111111111111111111118800000000000000000000000000000055
11118800000000000007700000000000077777770000000000000088111111111111111111111111111111111111118800000000000000000000000000000055
11118800000000000007700000000000000077770000000000000888111111111111111111111111111111111111118880000000000000000000000000000005
11118800000000000077700000000000000077000000000000000881111111111111111111111111111111111111111880000000000000000000000000000000
11188800000000000077000000000000000077700000000000008881111111111111111111111111111111111111111880000000000000000000000000000000
11188000000000000077000000000000000007700000000000008811111111111111111111111111111111111111111888000000000000000000000000000000
11188000007770000077000000000000000007700077000000088811111111111111111111111111111111111111111188000000000000000000000000000000
11188000007777700777000000000000000007707777000000088111111111111111111111111111111111111111111188000000000000000000000000000000
11188000000777777770000000000000000007777770000000088111111111111111111111111111111111111111111188000000000000000000000000000000
11188000000077777770000000000000000000777770000000888111111111111111111111111111111111111111111188800000000000000000000000000000
11188000000000777770000000000000000000777700000000881111111111111111111111111111111111111111111118800000000000000000000000000000
11188000000000077700000000000000000000777700000008881111111111111111111111111111111111111111111118800000000000000000000000000000
11888000000000007700000000000000000000077000000008811111111111111111111111111111111111111111111118800000000000000000000000000000
11880000000000000000000000000000000000000000000088811111111111111111111111111111111111111111111118880000000000000000000000000000
11880000000000000000000000000000000000000000000088111111111111111111111111111111111111111111111111880000000000000000000000000000
11880000000000000000000008888888888888888888888888111111111111111111111111111111111111111111111111880000000000000000000000000000
11888888888888888888888888888888888888888888888881111111111111111111111111111111111111111111111111888000000000000000000000000000
11888888888888888888888888111111111111111111111111111111111111111111111111111111111111111111111111188000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111188000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111188000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111188800000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111118800000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111118800000000000000000000000000

__gff__
0000000000000001020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3939393939393939393939393939393900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3939393939393939393939393939393900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070707070707070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252525252525252525252525252500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252525252525252525252525252500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252525252525252525252525252500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252525252525252525252525252500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010107475767710101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010108485868710101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
100a101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070707070707070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010f000005135051050c00005135091351c0150c1351d0150a1351501516015021350713500000051350000003135031350013500000021351b015031351a0150513504135000000713505135037153c7001b725
010f00000c03300000300152401524615200150c013210150c003190151a01500000246153c70029515295150c0332e5052e5150c60524615225150000022515297172b71529014297152461535015295151d015
010f000007135061350000009135071351f711000000510505135041350000007135051351c0151d0150313503135021350000005135031350a1050a135000000113502135031350413505135000000a13500000
010f00000c033225152e5153a515246152b7070a145350150c003290153200529005246152501526015220150c0331e0251f0252700524615225051a0152250522015225152201522515246150a7110a0001d005
0112000003744030250a7040a005137441302508744080251b7110a704037440302524615080240a7440a02508744087250a7040c0241674416025167251652527515140240c7440c025220152e015220150a525
011200000c033247151f5152271524615227151b5051b5151f5201f5201f5221f510225212252022522225150c0331b7151b5151b715246151b5151b5051b515275202752027522275151f5211f5201f5221f515
011200000c0330802508744080250872508044187151b7151b7000f0251174411025246150f0240c7440c0250c0330802508744080250872508044247152b715275020f0251174411025246150f0240c7440c025
011200002452024520245122451524615187151b7151f71527520275202751227515246151f7151b7151f715295202b5212b5122b5152461524715277152e715275002e715275022e715246152b7152771524715
011200002352023520235122351524615177151b7151f715275202752027512275152461523715277152e7152b5202c5212c5202c5202c5202c5222c5222c5222b5202b5202b5222b515225151f5151b51516515
011200000c0330802508744080250872508044177151b7151b7000f0251174411025246150f0240b7440b0250c0330802508744080250872524715277152e715080242e715080242e715246150f0240c7440c025
011600000042500415094250a4250042500415094250a42500425094253f2050a42508425094250a425074250c4250a42503425004150c4250a42503425004150c42500415186150042502425024250342504425
011600000c0330c4130f54510545186150c0330f545105450c0330f5450c41310545115450f545105450c0230c0330c4131554516545186150c03315545165450c0330c5450f4130f4130e5450e5450f54510545
0116000005425054150e4250f42505425054150e4250f425054250e4253f2050f4250d4250e4250f4250c4250a4250a42513425144150a4250a42513425144150a42509415086150741007410074120441101411
011600000c0330c4131454515545186150c03314545155450c033145450c413155451654514545155450c0230c0330c413195451a545186150c033195451a5451a520195201852017522175220c033186150c033
010b00200c03324510245102451024512245122751127510186151841516215184150c0031841516215134150c033114151321516415182151b4151d215224151861524415222151e4151d2151c4151b21518415
011400001051512515150151a5151051512515150151a5151051512515150151a5151051512515150151a5151051512515170151c5151051512515170151c5151051512515160151c5151051512515160151c515
011400000c0330253502525020450e6150252502045025250c0330253502525020450e6150252502045025250c0330252502045025350e6150204502535025250c0330253502525020450e615025250204502525
011400002c7252c0152c7152a0252a7152a0152a7152f0152c7252c0152c7152801525725250152a7252a0152072520715207151e7251e7151e7151e715217152072520715207151e7251e7151e7151e7151e715
011400000c0330653506525060450e6150652506045065250c0330653506525060450e6150652506045065250c0330952509045095350e6150904509535095250c0330953509525090450e615095250904509525
0114000020725200152071520015217252101521715210152c7252c0152c7152c0152a7252a0152a7152a015257252501525715250152672526015267153401532725310152d715280152672525015217151c015
010e000005145185111c725050250c12524515185150c04511045185151d515110250c0451d5151d0250c0450a0451a015190150a02505145190151a015050450c0451d0151c0150012502145187150414518715
010e000021745115152072521735186152072521735186052d7142b7142971426025240351151521035115151d0451c0051c0251d035186151c0251d035115151151530715247151871524716187160c70724717
010e000002145185111c72502125091452451518515090250e045185151d5150e025090451d5151d025090450a0451a015190150a02505045190151a015050450c0451d0151c0150012502145187150414518715
010e000029045000002802529035186152802529035000001a51515515115150e51518615000002603500000240450000023025240351861523025240350000015515185151c51521515186150c615280162d016
010e000002145185112072521025090452451518515090450e04521515265150e025090451d5151d01504045090451d01520015210250414520015210250404509045280152d0150702505145187150414518715
011a00000173401025117341102512734120250873408025127341202501734010251173411025087340802505734050250d7340d025147341402506734060250873408025127341202511734110250d7340d025
010d00200c0331b51119515195152071220712145151451518615317151d5151d515125050c03314515145150c0330150519515195150d517205161451514515186153171520515205150d5110c033145150c033
011a00000a7340a02511734110250d7340d02505734050250673406025147341402511734110250d7340d0250a7340a02511734110250d7340d02508734080250373403025127341202511734110250d7340d025
010d00200c0331b511295122951220712207122c5102c51018615315143151531514295150c03329515295150c0330150525515255150d517205162051520515186153171520515205150d5110c033145150c033
01180000021100211002110021120e1140e1100e1100e1120d1140d1100d1100d1120d1120940509110091120c1100c1100c1100c1120b1110b1100b1100b1120a1100a1100a1100a11209111091100911009112
01180000117201172011722117221d7201d7201d7221d7221c7211c7201c7201c7201c7221c72218720187221b7211b7201b7201b7201b7221b7221d7221d7221a7201a7201a7201a7201a7221a7221672016722
011800001972019720197221972218720187201872018720147201472015720157201f7211f7201d7201d7201c7201c7201c7221c7221a7201a7201a7221a7251a7201a7201a7221a72219721197201972219722
011800001a7201a7201a7221a7221c7201c7201c7221c7221e7201e7202172021720247212472023720237202272022720227202272022722227221f7201f7202272122720227202272221721217202172221722
0118000002114021100211002112091140911009110091120e1140e1100c1100c1120911209110081100811207110071100711007112061110611006110061120111101110011100111202111021100211002112
0118000020720207202072220722217202172021722217222b7212b72029720297202872128720267202672526720267202672026720267222672228721287202672026720267202672225721257202572225722
010e00000c0231951517516195150c0231751519516175150c0231951517516195150c0231751519516175150c023135151f0111f5110c0231751519516175150c0231e7111e7102a7100c023175151951617515
010e000000130070200c51000130070200a51000130070200c51000130070200a5200a5200a5120a5120a51200130070200c51000130070200a51000130070200c510001300b5200a5200a5200a5120a5120a512
010e00000c0231e5151c5161e5150c0231c5151e5161c5150c0231e5151c5161e5150c0231c5151e5161c5150c0230c51518011185110c0231c5151e5161c5150c0231e7111e7102a7100c023175151951617515
010e0000051300c02011010051300c0200f010051300c02011010051300c0200f0200f0200f0120f0120f012061300d02012010071300e02013010081300f0201503012020140101201015030120201401012010
010700000c5370f0370c5270f0270f537120370f527120271e537230371e527230272f537260372f52726027165371903716527190271c537190371c527210271c53621036245262102624536330362452633026
018800000074400730007320073200730007300073200732007300073200730007320073000732007320073200732007300073000730007320073000730007300073200732007300073000732007300073200732
01640020070140801107011060110701108011070110601100013080120701106511070110801707012060110c013080120701106011050110801008017005350053408010070110601100535080170701106011
018800000073000730007320073200730007300073200732007300073200730007320073000732007320073200732007300073000730007320073000730007300073200732007300073000732007300073200732
0164002006510075110851707512060110c0130801207011060110501108017070120801107011060110701108011075110651100523080120701108017005350053408012070110601100535080170701106511
011800001d5351f53516525275151d5351f53516525275151f5352053518525295151f5352053518525295151f5352053517525295151f5352053517525295151d5351f53516525275151d5351f5351652527515
010c00200c0330f13503130377140313533516337140c033306150c0330313003130031253e5153e5150c1430c043161340a1351b3130a1353a7143a7123a715306153e5150313003130031251b3130c0331b313
010c00200c0331413508130377140813533516337140c033306150c0330813008130081253e5153e5150c1330c0430f134031351b313031353a7143a7123a715306153e5150313003130031251b3130c0333e515
011800001f5452253527525295151f5452253527525295151f5452253527525295151f5452253527525295151f5452353527525295151f5452353527525295151f5452253527525295151f545225352752529515
010c002013035165351b0351d53513025165251b0251d52513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165251b0351d545
011200000843508435122150043530615014351221502435034351221508435084353061512215054250341508435084350043501435306150243512215034351221512215084350843530615122151221524615
011200000c033242352323524235202351d2352a5111b1350c0331b1351d1351b135201351d135171350c0330c0332423523235202351d2351b235202352a5110c03326125271162c11523135201351d13512215
0112000001435014352a5110543530615064352a5110743508435115152a5110d43530615014352a511084150d4350d4352a5110543530615064352a5110743508435014352a5110143530615115152a52124615
011200000c033115152823529235282352923511515292350c0332823529216282252923511515115150c0330c033115151c1351d1351c1351d135115151d1350c03323135115152213523116221352013522135
0112000001435014352a5110543530615064352a5110743508435115152a5110d435306150143502435034350443513135141350743516135171350a435191351a1350d4351c1351d1351c1351d1352a5001e131
011200000c033115152823529235282352923511515292350c0332823529216282252923511515115150c0330c033192351a235246151c2351d2350c0331f235202350c033222352323522235232352a50030011
0114001800140005351c7341c725247342472505140055352173421725287342872504140045351f7341f725247342472502140025351d7341d72524734247250000000000000000000000000000000000000000
011400180c043287252b0152f72534015377253061528725290152d72530015377250c0432f7253001534725370153c725306152b7252d01532725370153b7250000000000000000000000000000000000000000
0114001809140095351f7341f7252473424725091400953518734187251f7341f72505140055351f7341f7252473424725051400553518734187251f7341f7250000000000000000000000000000000000000000
0114001802140025351f7341f725247342472504140045351f7341f725247342472505140055352b7242b715307243071507140075352b7242b71534724347150000000000000000000000000000000000000000
011400180c0433772534015307252f0152d725306152d7252f0153072534015377250c0433772534015307252f0152d725306152d7252f0153072534015377250000000000000000000000000000000000000000
011400180c0433c7253701534725300152f725306152f7253001534725370153c7250c0433c7253701534725300152f725306152f7253001534725370153c7250000000000000000000000000000000000000000
011400180c043287252b0152f725340153772530615287252901530725370153c7250c043287252901530725370153c72530615287252901530725370153c7250000000000000000000000000000000000000000
011400180c003287052b0052f705340053770530605287052900530705370053c7050c0032f7053000534705370053c705306052b7052d00532705370053b7050000000000000000000000000000000000000000
000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00014344
00 00014344
01 00014344
00 00014344
00 02034344
02 02034344
00 04424344
00 04424344
00 04054344
00 04054344
01 04054344
00 04054344
00 06074344
02 08094344
01 0a0b4344
00 0c0d4344
00 0a0e4344
02 0c0e4344
00 10424344
01 100f4344
00 100f4344
00 10114344
00 12114344
02 12134344
01 14154344
00 14154344
00 16154344
00 16154344
00 18174344
02 16174344
00 19424344
01 191a4344
00 191a4344
00 1b1a4344
00 191c4344
02 1b1c4344
01 1d1e4344
00 1d1f4344
00 1d1e4344
00 1d1f4344
00 21204344
02 1d224344
00 27424344
01 24234344
00 24234344
02 26254344
01 28294344
03 2a2b4344
01 2d304344
00 2e304344
00 2d304344
00 2e304344
00 2d2c4344
00 2d2c4344
02 2e2f4344
01 31324344
00 31324344
00 33344344
02 35364344
01 3738433f
00 3738433f
00 393b433f
00 393c433f
02 3a3d433f

