##################################################
#                                                #
#        EP1 - Parte 2: Metodo de Newton         #
#                                                #
#        Pedro Pereira     - NUSP 9778794        #
#        Raphael R. Gusmao - NUSP 9778561        #
#                                                #
##################################################
1;

f = @(x) x.^4 - 1;
df = @(x) 4*x.^3;

################################################################################
function newton_basins(f, df, l, u, p)
% newton_basins(f, df, la, u, p)
%   Acha as bacias de convergencia da funcao f (com  primeira  derivada  df)  no
%   dominio [l, u]x[l, u] e gera um arquivo output.txt que contem os dados  para
%   a geracao da imagem das bacias. Os dados gerados preenchem  uma  imagem  com
%   pxp pixels.
    file = fopen('output.txt', 'w');
    
    lin = linspace(l, u, p);
    [X, Y] = meshgrid(lin, lin);
    z = X + Y*i;
    z = newton(f, df, z);

    for i = 1:p
        for j = 1:p
            if (!isnan(z(i, j)))
                root = z(i, j);
                rReal = real(root);
                rImag = imag(root);
                hash = floor(mod(rReal, 1997) + mod(rImag*6661, 1997));
                fprintf(file, "%d\t\t%d\t\t%d\n", i, j, hash);
            else
                fprintf(file, "%d\t\t%d\t\t0\n", i, j);
            endif
        endfor
    endfor

    fclose(file);
endfunction

################################################################################
function [x0] = newton(f, df, x0)
% [x0] = newton(f, df, x0)
%   Aplica o metodo de Newton para achar uma raiz  da  funcao  f  (com  primeira
%   derivada df), partindo do ponto x0.
    max = 1000;
    atol = 10^-6;
    i = 1;
    do
        prev = x0;
        x0 = x0 - f(x0)./df(x0);
        i = i + 1;
    until (i >= max || abs(x0 - prev) < atol)
endfunction