#############################################################
#                                                           #
#       Newton basins calculator                            #
#       by:                                                 #
#           Pedro Pereira,  nusp. 9778794                   #
#           Raphael Gusmão, nusp. 9778561                   #
#                                                           #
#############################################################

1;

f = @(x) x.^4 - 1;
#df = @(x) 4*x^3;

################################################################################
function newton_basins(f, l, u, p)
% newton_basins(f, la, u, p)
%   Acha as bacias de convergencia da funcao f no  dominio  [l1, u1]x[l2, u2]  e
%   gera um arquivo output.txt que contem os dados para a geracao da imagem  das
%   bacias. Os dados gerados preenchem uma imagem com p1xp2 pixels.
    file = fopen('output.txt', 'w');

    df = @(x) 4*x.^3;

    x = linspace(l, u, p);
    y = linspace(l, u, p);
    [X, Y] = meshgrid(x, y);

    z = X + Y*i;
    z = newton(f, df, z);

    for i = 1:p
        for j = 1:p
            if(!isnan(z(i, j)))
                color = floor(real(z(i, j)));########################### ARRUMAR
                fprintf(file, "%d\t\t%d\t\t%d\n", i, j, color);
            else
                fprintf(file, "%d\t\t%d\t\t0\n", i, j);
            endif
        endfor
    endfor

    fclose(file);
endfunction

################################################################################
function [x0] = newton(f, df, x0)
% [x0, converged] = newton(f, df, x0)
%   Aplica o metodo de Newton para achar uma raiz  da  funcao  f  (com  primeira
%   derivada df), partindo do ponto x0.
    max = 1000;
    atol = 10^-16;
    i = 1;
    do
        prev = x0;
        x0 = x0 - f(x0)./df(x0);
        i = i + 1;
    until (i >= max || abs(x0 - prev) < atol)
endfunction
