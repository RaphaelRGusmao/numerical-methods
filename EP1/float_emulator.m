################################################################################
#                                                                              #
#                       EP1 - Parte 1:  Emulador de floats                     #
#                                                                              #
#                       Pedro Pereira     - NUSP 9778794                       #
#                       Raphael R. Gusmao - NUSP 9778561                       #
#                                                                              #
################################################################################


# Makes octave work with 15 decimal places of precision.
format long;

# RETURNS: exponent of number
# Finds exponent of number
function ret = find_expo(number)
    expo = -127;
    if(number < 0)
        number = -number;
    endif
    while(number / 2 ^ expo >= 1)
        expo += 1;
    endwhile
    ret = expo - 1;
endfunction

# RETURNS: unit in the last place of number
# Finds unit in the last place of number
function ulp = find_ulp(number)
    epsilon = 1 / (2 ^ 23);
    ulp = epsilon * 2 ^ find_expo(number);
endfunction

# RETURNS: a vector containing:
# index 1: X-, takes care of signal
# index 2-24: series of 0's and 1's that
# represents the number in floating point.
function ret = truncate(number)
    orig_number = number;
    isneg = false;
    # Sticky bit
    sticky = 0;
    # Guard bits
    guard = [0; 0];
    # Always works with positive numbers
    if(number < 0)
        isneg = true;
        number = -number;
    endif
    expo = find_expo(number);
    i = expo - 1;
    tr = 2 ^ expo;
    ve = [];
    remainder = number - 2 ^ expo;
    # Division algorithm
    while(i >= expo - 23)
        if(remainder / 2 ^ i >= 1)
            tr += 2 ^ i;
            remainder -= 2 ^ i;
            ve = [ve; 1];
        else
            ve = [ve; 0];
        endif
        i -= 1;
    endwhile
    # Treats the negative cases. Rounds always to X-.
    if(isneg)
        tr = -tr;
        if(orig_number != tr)
            tr -= find_ulp(tr);
        endif
    endif
    if(remainder > 0)
        # sticky bit
        sticky = 1;
    endif
    ret = [tr; ve; guard; sticky];
endfunction


# RETURNS: number represented in floating-point,
# Rounded as described in "method".
#
# Available methods:
#   "-inf"    : rounds towards negative infinity
#   "inf"     : rounds towards positive infinity
#   "zero"    : rounds towards zero
#   "closest" : rounds to closest representable number
# Available verboseness:
#   "verbose" : prints the vector of truncation of the used number and
#               sticky bit.
#   "normal"  : only returns the number.
function ret = round(number, method, verbose)
    ulp = find_ulp(number);
    xneg_vector = truncate(number);
    xpos_vector = truncate(xneg_vector(1) + ulp);
    xneg = xneg_vector(1);
    xpos = xpos_vector(1);
    numerand_vector_xneg = xneg_vector(2:24)';
    numerand_vector_xpos = xpos_vector(2:24)';
    guard_xneg = xneg_vector(25:26)';
    guard_xpos = xpos_vector(25:26)';
    sticky = truncate(number)(27);
    if(strcmpi(method, "-inf"))
        # Rounds downwards
        ret = xneg;
        if(strcmpi(verbose, "verbose"))
            number
            numerand_vector_xneg
            guard_xneg
            sticky
        endif

    elseif(strcmpi(method, "inf"))
        # Rounds upwards
        ret = xpos;
        if(strcmpi(verbose, "verbose"))
            number
            numerand_vector_xpos
            guard_xpos
            sticky
        endif

    elseif(strcmpi(method, "zero"))
        # Rounds to zero
        if(number < 0)
            ret = xpos;
            if(strcmpi(verbose, "verbose"))
                number
                numerand_vector_xpos
                guard_xpos
                sticky
            endif
        else
            ret = xneg;
            if(strcmpi(verbose, "verbose"))
                number
                numerand_vector_xneg
                guard_neg
                sticky
            endif
        endif
    else
        # Rounds to closest
        if(abs(number - xneg) < abs(number - xpos))
            ret = xneg;
            if(strcmpi(verbose, "verbose"))
                number
                numerand_vector_xneg
                guard_xneg
                sticky
            endif
        elseif(abs(number - xneg) > abs(number - xpos))
            ret = xpos;
            if(strcmpi(verbose, "verbose"))
                number
                numerand_vector_xpos
                guard_xpos
                sticky
            endif
        else
            # Same distance: chooses the one that rounds to zero
            if(numerand_vector_xneg(23) == 0)
                ret = xneg;
                if(strcmpi(verbose, "verbose"))
                    number
                    numerand_vector_xneg
                    guard_xneg
                    sticky
                endif
            else
                ret = xpos;
                if(strcmpi(verbose, "verbose"))
                    number
                    numerand_vector_xpos
                    guard_xpos
                    sticky
                endif
            endif
        endif
    endif
endfunction

# RETURNS: the rounding of the addition of two numbers.
# see methods and verboseness of round().
function ret = add(x, y, method, verbose)
    # Is this actually a subtraction?
    if(y < 0)
        ret = subtract(x, -y, method, verbose);
    else
        # First of all, rounds received numbers.
        x = truncate(round(x, method, verbose));
        y = truncate(round(y, method, verbose));
        expoX = find_expo(x(1));
        expoY = find_expo(y(1));
        # If y's exponent is bigger, switch.
        if(expoY > expoX)
            temp = x;
            x = y;
            y = temp;
            temp = expoX;
            expoX = expoY;
            expoY = temp;
        endif
        # Are the exponents equal?
        if(expoY == expoX)
            # The result will always have a bigger exponent
            if(strcmpi(verbose, "verbose"))
                printf("=============================================\n")
                printf("Exponents are equal already, no work done.\n")
                printf("=============================================\n");
            endif
            expoX += 1;
            carry = 0;
            # In-place sum.
            # Sums x and y into x.
            # Goes into guard bits' range.
            for i = 26:-1:2
                x(i) = x(i) + y(i) + carry;
                carry = (x(i) > 1);
                x(i) = mod(x(i), 2);
            endfor
            # And then moves everything one slot down
            for i = 26:-1:3
                x(i) = x(i - 1);
            endfor
            x(2) = carry;
        else
            # Equal exponents
            show_hidden_bit = 0;
            while(expoY < expoX)
                # Takes every numerand down an exponent
                # Goes into guard bits' range.
                for i = 26:-1:3
                    y(i) = y(i - 1);
                endfor
                # Has the hidden bit already appeared?
                if(show_hidden_bit)
                    y(2) = 0;
                else
                    y(2) = 1;
                    show_hidden_bit = 1;
                endif
                # And then increments expoY
                expoY += 1;
            endwhile
            if(strcmpi(verbose, "verbose"))
                printf("=============================================\n");
                printf("After adjusting exponents:\n");
                x
                y
                printf("=============================================\n");
            endif
            # General case: expoX was bigger than expoY and
            # x + y < 2 ^ (expoX + 1)
            # Goes into guard bits' range.
            carry = 0;
            for i = 26:-1:2
                x(i) = x(i) + y(i) + carry;
                carry = (x(i) > 1);
                x(i) = mod(x(i), 2);
            endfor
        endif
        # Would do a decode to float function, but this
        # serves the same purpose, and returns the same number.
        x(1) = round(x(1) + y(1), method, "normal");
        # Sticky bit will always be on if one of them is on.
        x(27) = x(27) | y(27);
        # Result will be on x.
        ret = x;
    endif
endfunction

# RETURNS: the rounding of the subtraction of two numbers.
# see methods and verboseness of round().
function ret = subtract(x, y, method, verbose)
    # Is this actually a sum?
    if(y < 0)
        ret = add(x, -y, method, verbose);
    else
        # First of all, rounds received numbers.
        x = truncate(round(x, method, verbose));
        y = truncate(round(y, method, verbose));
        expoX = find_expo(x(1));
        expoY = find_expo(y(1));
        expoResult = find_expo(x(1) - y(1));
        # Adjusts exponents
        show_hidden_bit = 0;
        # Where to add 1 in 2's compliment
        add_one = 24;
        while(expoY < expoX)
            # Takes every numerand down an exponent
            for i = 26:-1:3
                y(i) = y(i - 1);
            endfor
            # Has the hidden bit already appeared?
            if(show_hidden_bit)
                y(2) = 0;
            else
                y(2) = 1;
                show_hidden_bit = 1;
            endif
            # And then increments expoY
            expoY += 1;
            add_one += 1;
        endwhile
        while(expoY > expoX)
            # Symetrical as above
            for i = 26:-1:3
                x(i) = x(i - 1);
            endfor
            if(show_hidden_bit)
                x(2) = 0;
            else
                x(2) = 1;
                show_hidden_bit = 1;
            endif
            expoX += 1;
            add_one += 1;
        endwhile
        if(strcmpi(verbose, "verbose"))
            printf("=============================================\n");
            printf("After adjusting exponents:\n");
            x
            y
            printf("=============================================\n");
        endif
        # Limits to guard bits
        if(add_one > 26)
            add_one = 26;
        endif
        # Does the two's compliment of y's numerands
        # First, negate each number
        for i = add_one:-1:2
            y(i) = !y(i);
        endfor
        # Then, add one
        y(add_one) += 1;
        carry = (y(add_one) >= 2);
        y(add_one) = mod(y(add_one), 2);
        for i = add_one-1:-1:2
            y(i) = y(i) + carry;
            carry = (y(i) >= 2);
            y(i) = mod(y(i), 2);
        endfor
        if(strcmpi(verbose, "verbose"))
            printf("=============================================\n")
            printf("2's compliment of y:\n");
            y
            printf("=============================================\n");
        endif
        # now adds them into x
        carry = 0;
        for i = 26:-1:2
            x(i) = x(i) + y(i) + carry;
            carry = (x(i) >= 2);
            x(i) = mod(x(i), 2);
        endfor
        # and then normalizes the number
        while(expoX > expoResult)
            # Takes each numerand up
            for i = 2:1:25
                x(i) = x(i + 1);
            endfor
            expoX -= 1;
        endwhile
        # The result will be exactly this
        x(1) = round(x(1) - y(1), method, "normal");
        x(27) = x(27) | y(27);
        ret = x;
    endif
endfunction
