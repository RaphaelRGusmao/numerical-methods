#############################################################
#                                                           #
#       Float precision emulator                            #
#       by:                                                 #
#           Pedro Pereira,  nusp. 9778794                   #
#           Raphael Gusmão, nusp. 9778561                   #
#                                                           #
#############################################################

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
    # sticky bit
    sticky = 0;
    if(number < 0)
        isneg = true;
        number = -number;
    endif
    expo = find_expo(number);
    i = expo - 1;
    tr = 2 ^ expo;
    ve = [];
    guard = [];
    remainder = number - 2 ^ expo;
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
    while(i >= expo - 25)
        if(remainder / 2 ^ i >= 1)
            guard = [guard; 1];
            remainder -= 2 ^ i;
        else
            guard = [guard; 0];
        endif
        i -= 1;
    endwhile
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
            numerand_vector_xneg
            guard_xneg
            sticky
        endif

    elseif(strcmpi(method, "inf"))
        # Rounds upwards
        ret = xpos;
        if(strcmpi(verbose, "verbose"))
            numerand_vector_xpos
            guard_xpos
            sticky
        endif

    elseif(strcmpi(method, "zero"))
        # Rounds to zero
        if(number < 0)
            ret = xpos;
            if(strcmpi(verbose, "verbose"))
                numerand_vector_xpos
                guard_xpos
                sticky
            endif
        else
            ret = xneg;
            if(strcmpi(verbose, "verbose"))
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
                numerand_vector_xneg
                guard_xneg
                sticky
            endif
        elseif(abs(number - xneg) > abs(number - xpos))
            ret = xpos;
            if(strcmpi(verbose, "verbose"))
                numerand_vector_xpos
                guard_xpos
                sticky
            endif
        else
            # Same distance: chooses the one that rounds to zero
            if(numerand_vector_xneg(23) == 0)
                ret = xneg;
                if(strcmpi(verbose, "verbose"))
                    numerand_vector_xneg
                    guard_xneg
                    sticky
                endif
            else
                ret = xpos;
                if(strcmpi(verbose, "verbose"))
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
    x = truncate(round(x, method, verbose));
    y = truncate(round(y, method, verbose));
    expoX = find_expo(x(1));
    expoY = find_expo(y(1));
    expoSum = 0;
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
        expoX += 1;
        carry = 0;
        # In-place sum.
        # Sums x and y into x.
        for i = 24:-1:2
            x(i) = x(i) + y(i) + carry;
            carry = (x(i) > 1);
            x(i) = mod(x(i), 2);
        endfor
        #

    else
        # Equal exponents
        while(expoY < expoX)
            # Takes every numerand down an exponent
            for i = 24:-1:3
                y(i) = y(i - 1);
            endfor
            y(2) = 0;
            # And then increments expoY
            expoY += 1;
        endwhile
        # General case: expoX was bigger than expoY and
        # x + y < 2 ^ (expoX + 1)
        carry = 0;
        for i = 24:-1:2 # TODO

        endfor
    endif
endfunction

# RETURNS: the rounding of the subtraction of two numbers.
# see methods and verboseness of round().
function ret = subtract(x, y, method, verbose)
    ret = round(round(x, method, verbose) - round(y, method, verbose), method, verbose);
endfunction
