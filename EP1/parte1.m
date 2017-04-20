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

# Finds unit in the last place of number
function ulp = find_ulp(number)
    epsilon = 1 / (2 ^ 23);
    ulp = epsilon * 2 ^ find_expo(number);
endfunction

# RETURNS: a vector containing:
# index 1: X-, takes care of signal
# index 2-24: series of 0's and 1's that
# represent the number in floating point.
function ret = truncate(number)
    orig_number = number;
    isneg = false;
    if(number < 0)
        isneg = true;
        number = -number;
    endif
    expo = find_expo(number);
    i = expo - 1;
    tr = 2 ^ expo;
    ve = [];
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
    if(isneg)
        tr = -tr;
        if(orig_number != ret)
            tr -= find_ulp(tr);
        endif
    endif
    ret = [tr; ve];
endfunction


# Available methods:
#   -inf    : rounds towards negative infinity
#   inf     : rounds towards positive infinity
#   zero    : rounds towards zero
#   closest : rounds to closest representable number
function ret = round(number, method, verbose)
    ulp = find_ulp(number);
    xneg = truncate(number)(1);
    xpos = truncate(number)(1) + ulp;
    numerand_vector_xneg = truncate(number)(2:24)';
    numerand_vector_xpos = truncate(truncate(number)(1) + ulp)(2:24)';
    if(strcmpi(method, "-inf"))
        # Rounds downwards
        ret = xneg;
        if(strcmpi(verbose, "verbose"))
            numerand_vector_xneg
        endif

    elseif(strcmpi(method, "inf"))
        # Rounds upwards
        ret = xpos;
        if(strcmpi(verbose, "verbose"))
            numerand_vector_xpos
        endif

    elseif(strcmpi(method, "zero"))
        # Rounds to zero
        if(number < 0)
            ret = xpos;
            if(strcmpi(verbose, "verbose"))
                numerand_vector_xpos
            endif
        else
            ret = xneg;
            if(strcmpi(verbose, "verbose"))
                numerand_vector_xneg
            endif
        endif
    else
        # Rounds to closest
        if(abs(number - xneg) < abs(number - xpos))
            ret = xneg;
            if(strcmpi(verbose, "verbose"))
                numerand_vector_xneg
            endif
        elseif(abs(number - xneg) > abs(number - xpos))
            ret = xpos;
            if(strcmpi(verbose, "verbose"))
                numerand_vector_xpos
            endif
        else
            if(numerand_vector_xneg == 0)
                ret = xneg;
                if(strcmpi(verbose, "verbose"))
                    numerand_vector_xneg
                endif
            else
                ret = xpos;
                if(strcmpi(verbose, "verbose"))
                    numerand_vector_xpos
                endif
            endif
        endif
    endif
endfunction

function ret = add(x, y, method)
    ret = round(round(x, method) + round(y, method), method);
endfunction

function ret = subtract(x, y, method)
    ret = round(round(x, method) - round(y, method), method);
endfunction
