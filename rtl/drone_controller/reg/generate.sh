#!/bin/bash

# Note we use peakrdl for generation
echo "Generating Drone Controller Registers & Docs"

peakrdl regblock -o . drone_controller_reg_definition.rdl --cpuif obi-flat
peakrdl html -o doc drone_controller_reg_definition.rdl
peakrdl c-header -o ../../../sw/lib/inc/drone_controller_reg.h --std gnu99 drone_controller_reg_definition.rdl 