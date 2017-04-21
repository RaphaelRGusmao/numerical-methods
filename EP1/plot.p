################################################################################
#                                                                              #
#                                   GNUPLOT                                    #
#                                                                              #
#                       Pedro Pereira     - NUSP 9778794                       #
#                       Raphael R. Gusmao - NUSP 9778561                       #
#                                                                              #
################################################################################

set terminal png size 1000, 1000                    # Format and size
set output 'newton_basins.png'                      # File name

set palette rgbformulae 33,13,10                    # Color palette
set cbrange [0:3994]                                # Range of colors

unset cbtics                                        # Remove tics from color box
unset xtics                                         # Remove tics from X axis
unset ytics                                         # Remove tics from Y axis
unset key
set style data lines

plot 'output.txt' using 2:1:3 with image            # Plot
