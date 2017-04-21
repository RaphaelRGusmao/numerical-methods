##################################################
#                                                #
#                    GNUPLOT                     #
#                                                #
#        Pedro Pereira     - NUSP 9778794        #
#        Raphael R. Gusmao - NUSP 9778561        #
#                                                #
##################################################

set terminal png size 1000, 1000                 # Format and size
set output 'img.png'                             # File name

set xlabel "Real"                                # X axis name
set ylabel "Imaginary"                           # Y axis name

set palette rgbformulae 33,13,10                 # Color palette
set cbrange[0:1997]                              # Range of colors

unset cbtics                                     # Remove tics from color box
unset xtics                                      # Remove tics from X axis
unset ytics                                      # Remove tics from Y axis

plot 'output.txt' using 2:1:3 with image         # Plot
