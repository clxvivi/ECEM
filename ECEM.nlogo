globals[
  box-edge
  out-count
  exit-patch
  ALL-N;;number of all evacuees
  r;;individual vision radius
  angle
  max-V
  crowd-E
 ]

breed [particles particle]

particles-own[
  speed
  family
  memory;;记录同伴历史位置
  entropy
  ve
  va
  vc
  vs
  dv
  new-V
]

patches-own [
  field
  pentropy
]

to setup
  clear-all
  ;random-seed 1537

  set r 5
  set angle 200
  set ALL-N 200
  set max-V 2
  set crowd-E 0

  build-wall
  build-exits
  build-obstacle
  ask patches with [pcolor = white][set field distancexy box-edge 0]
  ask patches with [pcolor = black][set field 1000]
  ask patches with [pcolor = green][set field 0]
  ask patches [set pentropy 0]
  make-particles

  if show-trace?;;显示路径
    [ask particles [pen-down]]

  show "Initialization completed!"

  reset-ticks
end

to average;;实现多次仿真并计算平均结果
  let i num
  let aver-T 0
  let aver-crowdE 0
  loop [
    ifelse i = 0 [
      set aver-T aver-T / num
      set aver-crowdE aver-crowdE / num
      show word "Averge escape time is " aver-T
      show word "Average maximum crowd enropy is" aver-crowdE
      stop]
    [
      setup
      while [out-count < ALL-N]
      [go]
      set i i - 1
      set aver-T aver-T + ticks
      set aver-crowdE aver-crowdE + crowd-E
    ]
  ]
end

to go
  ask patches with [pcolor != black and pcolor != green][set pcolor white]

  if Recolor?
  [
    ask patches with [pcolor != black and pcolor != green][
      set pentropy calculate-entropy particles in-radius 1.5
      set pcolor 129.9 - pentropy * 35
    ]
    ask particles [ht]
    ask links [hide-link]
  ]

  move

  let tcrowd-E calculate-entropy particles
  if crowd-E < tcrowd-E [set crowd-E tcrowd-E ]

  check-exit

  if out-count = ALL-N
  [
    show word "Evacuation time is " ticks
    show word "Maximum crowd entropy is" crowd-E
    stop
  ]
  tick
end

to build-wall
  set box-edge max-pxcor
  ask patches [ set pcolor white ]
  ask patches with [ ((abs pxcor = box-edge) and (abs pycor <= box-edge)) or
                     ((abs pycor = box-edge) and (abs pxcor <= box-edge)) ]
  [set pcolor black]
end

to build-obstacle
  ask patches with [ pxcor > -8 and pxcor < -5 and pycor < 16 and pycor > 6] [set pcolor black]
  ask patches with [pxcor > 6  and pxcor < 10 and pycor > -16 and pycor < -10] [set pcolor black]
  ask patches with [pxcor < 3 and pxcor > -6 and pycor > -6 and pycor < -3] [set pcolor black]
end

to build-exits
  set exit-patch patches with [ (abs pycor <= 1) and (pxcor = box-edge)]
  ask exit-patch [set pcolor green]
end

to make-particles
  set-default-shape turtles "circle"
  create-particles ALL-N [setup-particle]
  foreach sort-on [who] particles [ the-particle ->
    ask the-particle [
      random-position
      while [overlapping?] [ random-position ]
    ]
  ]
  classify
end

to-report overlapping?
  report any? other particles with [distance myself < size] or pcolor = black
end

to setup-particle
  set size 0.6
  set speed random-normal 1.5 0.15
  set entropy 0
  set color gray
  set family nobody
  set memory nobody
end

to classify
  ask particles with [who < usp] [
    set color pink
    let myx xcor
    let myy ycor

    set family one-of other particles with [who >= usp and color != pink] in-radius usd;;选距离小于usd的粒子作同伴
    if family = nobody[set family min-one-of particles with [who >= usp and color != pink] [distance myself]]
    ask family [set color pink]
    create-link-with family
    ;[hide-link]
    set memory list [xcor] of family [ycor] of family
  ]
  ask particles with [color = pink and family = nobody]
  [ set family one-of link-neighbors
    set memory list [xcor] of family [ycor] of family
  ]
end

to random-position
  setxy one-of [1 -1] * random-float (box-edge - 0.5 - size / 2)
        one-of [1 -1] * random-float (box-edge - 0.5 - size / 2)
end

to check-exit
  ask exit-patch[
    if any? particles-here
    [
      set out-count out-count + count particles-here
      ask particles-here [die]
    ]
  ]
end

to move
  ask particles[
    let ax xcor
    let ay ycor
    ;;visual perception
    let visible-particles other particles in-cone r angle
    let visible-patches patches with [pcolor != black and pcolor != green] in-cone r angle
    if any? patches with [pcolor = black] in-cone r angle
    [
      let visible-obs patches with [pcolor = black] in-cone r angle
      let in-shadow nobody
      let all-shadow nobody
      ask visible-obs[
        let dxap1 pxcor + 0.5 - ax
        let dxap2 pxcor - 0.5 - ax
        let dyap1 pycor + 0.5 - ay
        let dyap2 pycor - 0.5 - ay
        let tr1 atan dxap1 dyap1
        let tr2 atan dxap1 dyap2
        let tr3 atan dxap2 dyap1
        let tr4 atan dxap2 dyap2
        let maxtr max (list tr1 tr2 tr3 tr4)
        let mintr min (list tr1 tr2 tr3 tr4)
        let od sqrt ((pxcor - ax) ^ 2 + (pycor - ay) ^ 2)

        ifelse dxap1 * dxap2 < 0 and dyap2 > 0
        [
          let alist sort (list tr1 tr2 tr3 tr4)
          set in-shadow visible-patches with [distancexy ax ay > od and pcolor != black
                                              and (atan (pxcor - ax) (pycor - ay) < item 1 alist or atan (pxcor - ax) (pycor - ay) > item 2 alist)]
        ][
          set in-shadow visible-patches with [distancexy ax ay > od and pcolor != black
                                              and atan (pxcor - ax) (pycor - ay) > mintr and atan (pxcor - ax) (pycor - ay) < maxtr]]
          set all-shadow (patch-set all-shadow in-shadow)
        ]
        set visible-patches visible-patches with [not member? self all-shadow]

        if [particles-here] of visible-patches != nobody
        [set visible-particles other particles-on visible-patches]
     ]

    set entropy calculate-entropy visible-particles
    let alpha entropy / 2

    let vx0 dx
    let vy0 dy
    let we uwe
    let wa uwa
    let wc uwc
    let ws uws

    ;;exit velocity
    let escapex 0
    let escapey 0
    let escape-goal min-one-of exit-patch [distance myself]
    ;;exit is visible or not?
    ifelse any? exit-patch in-radius r
    [
      if distancexy box-edge 0 < 2 [set wc 0]
    ]
    [
      ifelse not any? visible-patches [set escape-goal patch-ahead -1]
      [set escape-goal min-one-of visible-patches [distancexy box-edge 0]]
    ]
    set escapex ([pxcor] of escape-goal) - xcor
    set escapey ([pycor] of escape-goal) - ycor
    set ve sqrt (escapex ^ 2 + escapey ^ 2)

    ;;avoidance velocity
    let avoidx 0
    let avoidy 0
    if any? visible-particles with [distance myself < 2]
    [
      let close-p min-one-of visible-particles with [distance myself < 2] [distance myself]
      set avoidx xcor - [xcor] of close-p
      set avoidy ycor - [ycor] of close-p
    ]
    if any? patches with [pcolor = black] in-cone 2 angle
    [
      let close-o min-one-of patches with [pcolor = black] in-cone 2 angle [distance myself]
      set avoidx avoidx + xcor - [pxcor] of close-o
      set avoidy avoidy + ycor - [pycor] of close-o
    ]
    set va sqrt (avoidx ^ 2 + avoidy ^ 2)

    ;;cohesion velocity
    let coherex 0
    let coherey 0
    if any? visible-particles
    [
      let close-p visible-particles
      set coherex (sum [xcor] of close-p) / (count close-p) - xcor
      set coherey (sum [ycor] of close-p) / (count close-p) - ycor
    ]
    set vc sqrt (coherex ^ 2 + coherey ^ 2)

    ;;velocity update when don't seeking
    let dvx we * escapex + wa * avoidx + wc * coherex
    let dvy we * escapey + wa * avoidy + wc * coherey

    ;;seeking velocity
    let seekx 0
    let seeky 0
    if family != nobody
    [
      let df distance family
      let de distancexy box-edge 0
      let fde 0
      ask family [set fde distancexy box-edge 0 ]
      ;;whether to seek or not
      ifelse df <= usd or (de <= r and fde <= r)
      [  set color pink
         set memory list [xcor] of family [ycor] of family
         set vs 0
      ][
        ;;family is visible
        ifelse member? family visible-particles
        [ set color sky
          set memory list [xcor] of family [ycor] of family
          set seekx [xcor] of family - xcor
          set seeky [ycor] of family - ycor
        ]
        ;;family is non-visible
        [ set color black
          let fx item 0 memory
          let fy item 1 memory
          ifelse fx = xcor and fy = ycor[
            ask visible-patches [set pcolor 99]
            let goal nobody
            ifelse any? visible-patches[
              set goal one-of visible-patches
              ][set goal one-of neighbors with [pcolor != black]
            ]
            set seekx [pxcor] of goal - xcor
            set seeky [pycor] of goal - ycor
            ][set seekx fx - xcor
              set seeky fy - ycor
           ]
         ]
        ;;velocity update when seeking
        set vs sqrt (seekx ^ 2 + seeky ^ 2)
        set dvx ws * seekx + (1 - ws) * escapex
        set dvy ws * seeky + (1 - ws) * escapey
        ]
     ]

    set dv sqrt (dvx ^ 2 + dvy ^ 2)
    if dv > max-V [ set dvx dvx * max-V / dv
                    set dvy dvy * max-V / dv]
    set dv sqrt (dvx ^ 2 + dvy ^ 2)
    let new-vx alpha * vx0 + (1 - alpha) * dvx
    let new-vy alpha * vy0 + (1 - alpha) * dvy
    set new-V sqrt (new-vx ^ 2 + new-vy ^ 2)
    set speed min list max-V new-V
    ifelse (new-vx != 0) or (new-vy != 0) [set heading atan new-vx new-vy][show "speed is 0"]

    ;;velocity correction
    if patch-ahead speed != nobody
    [
      let gx xcor + speed * dx
      let gy ycor + speed * dy
      let dspeed speed + 0.3
      let theading heading

      if any? other particles with [distancexy gx gy < size] or patch-ahead dspeed = nobody or [pcolor] of patch-ahead dspeed = black
      [
        ;;decrease velocity in half
        set gx xcor + speed / 2 * dx
        set gy ycor + speed / 2 * dy
        set dspeed speed / 2 + 0.3
        ifelse any? other particles with [distancexy gx gy < size] or patch-ahead dspeed = nobody or [pcolor] of patch-ahead dspeed = black
        [
        ;; turn to the direction with the lowest crowd density
          let near-area patches with [pcolor != black] in-cone r angle
          face min-one-of near-area [count particles-here]
          set gx xcor + speed * dx
          set gy ycor + speed * dy
          set dspeed speed + 0.3
          if any? other particles with [distancexy gx gy < size] or patch-ahead dspeed = nobody or [pcolor] of patch-ahead dspeed = black
          [ set speed 0 ]
         ][ set speed speed / 2]
      ]

      ;;position update
      jump speed
      ]
 ]

end

to-report calculate-entropy [turtleset]
  let N count turtleset
  ifelse N != 0
  [
    ;;Velocity distribution of particles
    let a1 count turtleset with [ heading >= 0 and heading < 90 and speed >= 0 and speed < 0.5 ]
    let a2 count turtleset with [ heading >= 0 and heading < 90 and speed >= 0.5 and speed < 1 ]
    let a3 count turtleset with [ heading >= 0 and heading < 90 and speed >= 1 and speed < 1.5 ]
    let a4 count turtleset with [ heading >= 0 and heading < 90 and speed >= 1.5 and speed <= 2 ]
    let b1 count turtleset with [ heading >= 90 and heading < 180 and speed >= 0 and speed < 0.5 ]
    let b2 count turtleset with [ heading >= 90 and heading < 180 and speed >= 0.5 and speed < 1 ]
    let b3 count turtleset with [ heading >= 90 and heading < 180 and speed >= 1 and speed < 1.5 ]
    let b4 count turtleset with [ heading >= 90 and heading < 180 and speed >= 1.5 and speed <= 2 ]
    let c1 count turtleset with [ heading >= 180 and heading < 270 and speed >= 0 and speed < 0.5 ]
    let c2 count turtleset with [ heading >= 180 and heading < 270 and speed >= 0.5 and speed < 1 ]
    let c3 count turtleset with [ heading >= 180 and heading < 270 and speed >= 1 and speed < 1.5 ]
    let c4 count turtleset with [ heading >= 180 and heading < 270 and speed >= 1.5 and speed <= 2 ]
    let d1 count turtleset with [ heading >= 270 and heading < 360 and speed >= 0 and speed < 0.5 ]
    let d2 count turtleset with [ heading >= 270 and heading < 360 and speed >= 0.5 and speed < 1 ]
    let d3 count turtleset with [ heading >= 270 and heading < 360 and speed >= 1 and speed < 1.5 ]
    let d4 count turtleset with [ heading >= 270 and heading < 360 and speed >= 1.5 and speed <= 2 ]

    ;;Boltzmann entropy
      let vlist sort-by > (list a1 a2 a3 a4 b1 b2 b3 b4 c1 c2 c3 c4 d1 d2 d3 d4)
      let H 0
      let i 0
      while [ i < 16]
      [ set H H + ln Cf N item i vlist
        set N N - item i vlist
        set i i + 1]
      let k 0.0138
      report k * H
  ]
  [report 0]
end

;;combinatorial number C(a,b)
to-report Cf [a b]
  ifelse a = 0 or b = 0 [report 1][
    let i b
    let j 1
    while [i > 0]
    [ set j j * ( a - i + 1) / i
      set i i - 1]
    report j
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
792
593
-1
-1
14.0
1
25
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
5
11
71
44
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
88
11
151
44
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
5
123
139
156
show-trace?
show-trace?
1
1
-1000

PLOT
823
10
1197
160
Instantaneous Maximum of Velocity Components 
Time
Velocity
0.0
10.0
0.0
2.0
true
true
"" ""
PENS
"Ve" 1.0 0 -16777216 true "" "plot max [ve] of particles"
"Vc" 1.0 0 -7500403 true "" "plot max [vc] of particles"
"Va" 1.0 0 -2674135 true "" "plot max [va] of particles"
"Vs" 1.0 0 -11221820 true "" "plot max [vs] of particles"

PLOT
1199
10
1407
160
Mean Speed
Time
Vilocity
0.0
10.0
0.0
2.0
true
false
"" ""
PENS
"mean-v" 1.0 0 -7500403 true "" "plot mean [speed] of particles"

PLOT
823
467
1194
616
Instantaneous Entropy of People
Time
Entropy
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"max-E" 1.0 0 -16777216 true "" "plot max [entropy] of particles "
"mean-E" 1.0 0 -7500403 true "" "plot mean [entropy] of particles "
"min-E" 1.0 0 -2674135 true "" "plot min [entropy] of particles "

PLOT
1200
162
1407
312
Entropy of Whole Crowd
Time
Entropy
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot calculate-entropy particles"

BUTTON
86
76
166
109
Average
average
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
9
245
63
305
uwe
0.3
1
0
Number

INPUTBOX
68
245
122
305
uwa
0.2
1
0
Number

INPUTBOX
128
245
184
305
uwc
0.2
1
0
Number

INPUTBOX
9
174
63
234
usp
20.0
1
0
Number

INPUTBOX
68
175
122
235
usd
2.0
1
0
Number

PLOT
822
163
1197
313
Entropy of people in Area A,B and C
Time
Entropy
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Area A" 1.0 0 -16777216 true "" "plot calculate-entropy particles with [distancexy box-edge 0 <= 5]"
"Area B" 1.0 0 -7500403 true "" "plot calculate-entropy particles with [distancexy box-edge 0 <= 10 and distancexy box-edge 0 > 5]"
"Area C" 1.0 0 -2674135 true "" "plot calculate-entropy particles with [distancexy box-edge 0 <= 15 and distancexy box-edge 0 > 10]"

INPUTBOX
5
49
70
109
num
50.0
1
0
Number

SWITCH
12
318
125
351
Recolor?
Recolor?
1
1
-1000

INPUTBOX
127
175
184
235
uws
0.9
1
0
Number

PLOT
823
316
1197
466
Entropy of People in Area L,M and R
Time
Entropy
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Area M" 1.0 0 -16777216 true "" "plot calculate-entropy particles with [xcor > (box-edge - 5) and abs ycor <= 1.5 ]"
"Area L" 1.0 0 -7500403 true "" "plot calculate-entropy particles with [xcor > (box-edge - 5) and ycor > 1.5 and ycor <= 4.5]"
"Area R" 1.0 0 -2674135 true "" "plot calculate-entropy particles with [xcor > (box-edge - 5) and ycor < -1.5 and ycor >= -4.5]"

@#$#@#$#@
## WHAT IS IT?

(This model is an attempt to simulate the emergency evacuation for crowd with paired social groups. )

## HOW IT WORKS

(The agents follow three basic rules:"egress","avoid",and "cohere".Additionally, agents in social groups also follow another rule: "seek".

"egress"

"avoid"

"cohere"

"seek"
)

## HOW TO USE IT

(Setup: resets the simulation according to the parameters set by the sliders.

Go: starts and stops the simulation.

Average: repeats the simulation for "num" times,and reports the average results.

Recolor?: shows the entropy of people within 1.5m of each patch.
)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)


## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
