
�
I%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s
268*common2
create_project: 2

00:00:032

00:00:072	
690.0122	
236.438Z17-268h px� 
>
Refreshing IP repositories
234*coregenZ19-234h px� 
t
 Loaded user IP repository '%s'.
1135*coregen2-
+c:/Projects/ERN24004/IP/ip_repo/ad1/ad1_1_0Z19-1700h px� 
|
 Loaded user IP repository '%s'.
1135*coregen25
3c:/Projects/ERN24004/digilent/vivado-library-masterZ19-1700h px� 
j
"Loaded Vivado IP repository '%s'.
1332*coregen2!
C:/Xilinx/Vivado/2024.1/data/ipZ19-2313h px� 
_
Command: %s
53*	vivadotcl2.
,synth_design -top ad1 -part xc7z007sclg400-1Z4-113h px� 
:
Starting synth_design
149*	vivadotclZ4-321h px� 
{
@Attempting to get a license for feature '%s' and/or device '%s'
308*common2
	Synthesis2

xc7z007sZ17-347h px� 
k
0Got license for feature '%s' and/or device '%s'
310*common2
	Synthesis2

xc7z007sZ17-349h px� 
o
HMultithreading enabled for synth_design using a maximum of %s processes.4828*oasys2
2Z8-7079h px� 
a
?Launching helper process for spawning children vivado processes4827*oasysZ8-7078h px� 
N
#Helper process launched with PID %s4824*oasys2
27000Z8-7075h px� 
�
%s*synth2v
tStarting Synthesize : Time (s): cpu = 00:00:02 ; elapsed = 00:00:03 . Memory (MB): peak = 1161.961 ; gain = 453.441
h px� 
�
synthesizing module '%s'%s4497*oasys2
ad12
 29
5C:/Projects/ERN24004/IP/ip_repo/ad1/ad1_1_0/hdl/ad1.v2
48@Z8-6157h px� 
�
[In the module '%s' declared at '%s:%s', parameter '%s' used as named parameter override, %s4877*oasys2
ad1_slave_lite_v1_0_S00_AXI2O
MC:/Projects/ERN24004/IP/ip_repo/ad1/ad1_1_0/hdl/ad1_slave_lite_v1_0_S00_AXI.v2
42
C_S_AXI_DATA_WIDTH2
does not exist29
5C:/Projects/ERN24004/IP/ip_repo/ad1/ad1_1_0/hdl/ad1.v2
878@Z8-7136h px� 
�
!failed synthesizing module '%s'%s4496*oasys2
ad12
 29
5C:/Projects/ERN24004/IP/ip_repo/ad1/ad1_1_0/hdl/ad1.v2
48@Z8-6156h px� 
�
%s*synth2v
tFinished Synthesize : Time (s): cpu = 00:00:02 ; elapsed = 00:00:04 . Memory (MB): peak = 1271.023 ; gain = 562.504
h px� 
C
Releasing license: %s
83*common2
	SynthesisZ17-83h px� 
~
G%s Infos, %s Warnings, %s Critical Warnings and %s Errors encountered.
28*	vivadotcl2
102
02
02
3Z4-41h px� 
<

%s failed
30*	vivadotcl2
synth_designZ4-43h px� 
N
Command failed: %s
69*common2
Vivado Synthesis failedZ17-69h px� 
\
Exiting %s at %s...
206*common2
Vivado2
Wed Oct 30 16:27:39 2024Z17-206h px� 


End Record