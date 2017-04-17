#############################################################
#                                                           #
#       Float precision emulator                            #
#       by:                                                 #
#           Pedro Pereira,  nusp. 9778794                   #
#           Raphael Gusmão, nusp.                           #
#                                                           #
#############################################################

# Makes octave work with 15 decimal places of precision.
format long;

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

function ulp = find_ulp(number)
    epsilon = 1 / (2 ^ 23);
    ulp = epsilon * 2 ^ find_expo(number);
endfunction

# Returns X-, takes care of signal
function ret = truncate(number)
    orig_number = number;
    isneg = false;
    if(number < 0)
        isneg = true;
        number = -number;
    endif
    expo = find_expo(number);
    i = expo - 1;
    ret = 2 ^ expo;
    remainder = number - 2 ^ expo;
    while(i >= expo - 23)
        if(remainder / 2 ^ i >= 1)
            ret += 2 ^ i;
            remainder -= 2 ^ i;
        endif
        i -= 1;
    endwhile
    if(isneg)
        ret = -ret;
        if(orig_number != ret)
            ret -= find_ulp(ret);
        endif
    endif
endfunction


# Available methods:
#   -inf    : rounds towards negative infinity
#   inf     : rounds towards positive infinity
#   zero    : rounds towards zero
#   closest : rounds to closest representable number
function ret = round(number, method)
    ulp = find_ulp(number);

    if(strcmpi(method, "-inf"))
        # Rounds downwards
        ret = truncate(number);

    elseif(strcmpi(method, "inf"))
        # Rounds upwards
        ret = truncate(number) + ulp;

    elseif(strcmpi(method, "zero"))
        # Rounds to zero
        if(number < 0)
            ret = truncate(number) + ulp;
        else
            ret = truncate(number);
        endif
    else
        # Rounds to closest
        xneg = truncate(number);
        xpos = truncate(number) + ulp;
        if(abs(number - xneg) < abs(number - xpos))
            ret = xneg;
        else
            ret = xpos;
        endif
    endif
endfunction

function ret = add(x, y, method)
    ret = round(round(x, method) + round(y, method), method);
endfunction

function ret = subtract(x, y, method)
    ret = round(round(x, method) - round(y, method), method);
endfunction
