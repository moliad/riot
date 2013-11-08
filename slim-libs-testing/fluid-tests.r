rebol [
	; -- Core Header attributes --
	title: "Fluid tests"
	file: %fluid-tests.r
	version: 1.0.1
	date: 2013-11-7
	author: "Maxim Olivier-Adlhoch"
	purpose: "Fluid library test and example script"
	web: http://www.revault.org/
	source-encoding: "Windows-1252"

	; -- Licensing details  --
	copyright: "Copyright � 2013 Maxim Olivier-Adlhoch"
	license-type: "Apache License v2.0"
	license: {Copyright � 2013 Maxim Olivier-Adlhoch

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
		http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.}

	;-  / history
	history: {
		v1.0.0 - 2013-10-18
			-first release should test every function of v1.0.4 of fluid
	
		v1.0.1 - 2013-11-07
			-now tests fluid v1.0.8
	}
	;-  \ history

	;-  / documentation
	documentation: ""
	;-  \ documentation
]



;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- LIBS
;
;-----------------------------------------------------------------------------------------------------------

do %../../slim-libs/slim/slim.r

fl: slim/open/expose 'fluid 1.0.8  [  flow  probe-pool memorize ]
slim/open/expose 'liquid none [ content fill processor !plug link attach liquify ]
fl/von  ; uncomment to see debug of flow.


slim/vexpose
von


;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- PLUG TYPES
;
;-----------------------------------------------------------------------------------------------------------

; add plug classes to the catalogue, so they can be used within any flow block


;-------------------------
;-    !sum
;
; here we use 'PROCESSOR which is a high-level function from the liquid api which builds plug classes.
;-------------------------
memorize !sum-model: processor '!sum [
	fx: 0
	plug/liquid: foreach x data [fx: fx + any [all [number? x  x]  0 ]]
]


;-------------------------
;-    !int
;
; the following plug converts its current value to integer
;
; here we use a more low-level approach which uses more RAM but is more Rebol "style compliant" .
;-------------------------
memorize !int: make !plug [
	valve: make valve [
		type: '!int
		
		purify: func [
			plug
		][
			plug/liquid: to-integer plug/liquid
			false
		]
	]
]

;---
; we tell this plug to use itself as its own pipe server class.
; 
; thus, any pipe being served by this plug will send integers to all of its clients,
; even when filled with something else.
;---
!int/valve/pipe-server-class: !int





;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- PLUG INSTANCES
;
;-----------------------------------------------------------------------------------------------------------

p: liquify/fill !plug 100





;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- FLOW EXAMPLES AND TESTS
;
;-----------------------------------------------------------------------------------------------------------
;-    basic flow

vprint ""
vprint "---------------------------------------------"
vprint " basic Flow operations"
vprint "---------------------------------------------"
pool: flow/debug [

	a: #plug  ; liquify (instanciate) a new plug of type !plug (filled with nothing so far)
	a: 10     ; fill value into plug, using previously liquified plug since 'A already exists.
	
	b: 3      ; liquify a mew plug, using default type, and dumping value 3.  This is a basic container.
			  ; this basically imitates the previous two lines into one.

	ref: :b   ; create reference to another plug. (the same plug with two names)
	ref-p: :p ; create reference to external plug. (the plug is not within flow, but exists)
	
	;----
	; the following creates a new plug class on-the-fly and memorizes it for the rest of THIS flow.
	; once the flow is done, this class is not available anymore.
	;
	; internally, the plug/valve/type is set to !add
	;
	; ideally, you should not use this too often, since it duplicates classes at each call to flow, but
	; in many cases, you create plugs which are only used for one pool, so its handy.
	;
	; it can also be very useful for tools which create, save and load plugs on the fly. this means you can use
	; the flow dialect directly to express all parts of your project.
	;
	; notice that by using /debug, you get the catalogue within FLOW's result pool.
	#add: [
		vin ["adding up: " mold data]
		fx: 0
		plug/liquid: foreach x data [vprobe fx: fx + any [all [number? x  x]  0 ]]
		vout
	]
	
	total: #add    ; allocate an !add plug
	total < a      ; link a couple of plugs to total
	total < b      ;
	
	value: total   ; **PROCESS** 'TOTAL and fill 'VALUE with its result (doesn't copy series data)
				   ; note there is no link or connection between 'TOTAL or 'VALUE
				   
	a: 2           ; note that although 'TOTAL will react to 'A change, 'VALUE will not because its not linked.
	
]
probe-pool pool


;---------------------
;-    subpools
;---------------------
vprint ""
vprint "---------------------------------------------"
vprint " subpool manipulations"
vprint "---------------------------------------------"
pool: flow/debug [
	a: 10
	b: 1
	
	t: #sum [a b]  ; create a new !sum and link it to two other plugs, using a subpool, in one line.
	t2: #sum [ t sum: #sum [a b] #sum [a b] sum ] ; a more complex subpool which allocates additional !sum nodes 
												  ; and assigns one of them to the sum word in the pool.
												  ;
												  ; note that we use the sum plug directly within the graph!
	
]
probe-pool pool
	
	

	
;---------------------
;-    piping
;---------------------
vprint ""
vprint "---------------------------------------------"
vprint " piping manipulations"
vprint "---------------------------------------------"


pool: flow/debug [
	p1: "1"        ; generate three containers.
	p2: "2"
	p3: "3"
	
	p3 | p1 | p2   ; pipe the three containers ( the first plug is used to determine which one provides pipe server )
				   ; at this point they all share the same value
	
	i: #int        ; create an !int type plug
	i: "55"        ; set it to a loadable string
	
	i2: "22"
	i3: "33"
	i | i2 | i3    ; we now pipe values to 'I which will all contain an integer!
	
	ii: #int       ; an alternate just to show differences in pipe server master.
	ii: "66"       
	ii2: "77"      
	ii3: "88"      
	
	ii2 | ii | ii3  ; only 'II will be an integer because the pipe server is not setting int... only it is.
]
probe-pool pool




;---------------------
;-    inline model creation
;---------------------

; we turn on fluid's auto memorization feature, just to see if its working properly,
; this feature, will automatically add all new named models to the fluid's internal catalogue
fl/auto-memorize


vprint ""
vprint "---------------------------------------------"
vprint " inline model creation"
vprint "---------------------------------------------"
pool: flow/debug [
	x: 10
	blk: [ ]
	fx: ( vprobe "tADAM" plug/liquid: to-pair data/1 data/2 ) [ x x ]
	acc: (plug/liquid: data)
	fxx: #rejoin [ acc [ x x x fx ] ]
	issue: #to-issue [ fxx ]
]
probe-pool pool



;---------------------
;-    context import (in-line binding)
;---------------------
vprint ""
vprint "---------------------------------------------"
vprint " context import"
vprint "---------------------------------------------"
pool: flow [
	x: 6
]
other-pool: flow [
	x: 6
]


obj: context [
	x: 10
	y: 20
	z: 30
]

blah: context [
	a: 1
	b: 2
	c: 3
]

ctx: context [
	gr: blah
]

new-pool: flow/debug [
	; test importing a simple object
	/using obj
	obj-total: #sum [ x y z ]
	
	; test importing a pool
	/using pool
	x: 1
	Y: :x
	
	;/probe-pool
	
	; test re-binding to new pool
	/using other-pool
	x: 2
	s: #sum [ x y ]
	
	
	; paths are allowed to import contexts.
	/using ctx/gr
	gr-total: #sum [ a b c ]
]
probe-pool new-pool




;---------------------
;-    context sharing (in-line binding)
;---------------------
vprint ""
vprint "---------------------------------------------"
vprint " context sharing"
vprint "---------------------------------------------"


pool-x: context [
	x: 11
	y: 22
]

pool-z: context [
	z: p ; this plug will be reused within pool
	y: 55
]

pool: flow/debug [
	; test importing a simple object
	y: 100
	/sharing pool-x
	/sharing pool-z
	
	y: 200
	
	obj-total: #sum [  x  y  z  ]
]
probe-pool pool


ask "..."
