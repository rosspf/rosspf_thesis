#!/bin/bash

make pdf
acroread -openInNewInstance ./output/thesis.pdf &> /dev/null