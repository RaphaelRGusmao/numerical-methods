################################################################################
#                                                                              #
#              EP2: Interpolacao polinomial por partes bivariada               #
#                                                                              #
#                       Pedro Pereira     - NUSP 9778794                       #
#                       Raphael R. Gusmao - NUSP 9778561                       #
#                                                                              #
################################################################################
1;

################################################################################
function main()
    %disp("Escolha um dos metodos abaixo");
    %disp(" 1: Bilinear");
    %disp(" 2: Bicubico");
    %ax = input("Digite ax: "); bx = input("Digite bx: ");
    %ay = input("Digite ay: "); by = input("Digite by: ");
    %hx = input("Digite hx: "); hy = input("Digite hy: ");
    %disp("Escolha uma das funcoes abaixo");
    %disp(" 1: f(x,y) = xy");
    %disp(" 2: f(x,y) = x + y");
    %disp(" 3: f(x,y) = x^2 + y - 2");
    %nFun = input(" : ");
    metodo = 2; ax = 0; bx = 3; ay = 0; by = 3; hx = 1; hy = 1; nFun = 2;# Teste
    
    nx = 1+(bx-ax)/hx; ny = 1+(by-ay)/hy;
    
    f = dxf = dyf = dxyf = 0;
    if (nFun == 1)
        f = @(x, y) x.*y;
        dxf = @(x, y) 0*x + y;
        dyf = @(x, y) x + 0*y;
        dxyf = @(x, y) 0*x + 0*y;
    elseif (nFun == 2)
        f = @(x, y) x + y;
        dxf = @(x, y) 0*x + 0*y + 1;
        dyf = @(x, y) 0*x + 0*y + 1;
        dxyf = @(x, y) 0*x + 0*y;
    else % 3
        f = @(x, y) x.^2 - 2*y + 2;
        dxf = @(x, y) 2*x;
        dyf = @(x, y) 0*x + 0*y - 2;
        dxyf = @(x, y) 0*x + 0*y;
    endif
    
    x = linspace(ax, bx, nx);
    y = linspace(ay, by, ny);
    [X, Y] = meshgrid(x, y);
    F = f(X, Y);
    dxF = dxf(X, Y);
    dyF = dyf(X, Y);
    dxyF = dxyf(X, Y);
    
    coef = constroiv(metodo, ax, bx, ay, by, hx, hy, F, dxF, dyF, dxyF);
    
    V = zeros(nx, ny);
    F_V = zeros(nx, ny);
    for i = 1:nx
        for j = 1:ny
            V(i,j) = avaliav(metodo, x(i), y(j), x, y, nx, ny, hx, hy, coef);
            F_V(i, j) = abs(F(i, j) - V(i, j));
        endfor
    endfor
    
    disp("F")
    disp(F);
    disp("V")
    disp(V);
    disp("F_V")
    disp(F_V);
    
    draw("f", x, y, F);
    draw("v", x, y, V);
    draw("|f - v|", x, y, F_V);
end   

################################################################################
function ret = avaliav(metodo, x, y, X, Y, nx, ny, hx, hy, coef)
    i = 1;
    while (i+1 < nx && X(i+1) < x)
        i = i + 1;
    endwhile
    j = 1;
    while (j+1 < ny && Y(j+1) < y)
        j = j + 1;
    endwhile
    if (metodo == 1) # Metodo Bilinear
        m1 = [1, (x - X(i))/hx];
        m2 = [1; (y - Y(j))/hy];
        ret = m1 * coef(:,:, i, j) * m2;
    else # Metodo Bicubico
        m1 = [1, (x - X(i))/hx, ((x - X(i))/hx)^2, ((x - X(i))/hx)^3];
        m2 = [1; (y - Y(j))/hy; ((y - Y(j))/hy)^2; ((y - Y(j))/hy)^3];
        ret = m1 * coef(:,:, i, j) * m2;
    endif
end

################################################################################
function coef = constroiv(metodo, ax, bx, ay, by, hx, hy, F, dxF, dyF, dxyF)
    nx = 1+(bx-ax)/hx; ny = 1+(by-ay)/hy;
    if (metodo == 1) # Metodo Bilinear
        coef = zeros(2, 2, (nx-1),(ny-1));
        for i = 1:nx-1
            for j = 1:ny-1
                m1 = [1, 0;
                      1, 1];
                fMat = [F(i,j),    F(i, j+1);
                        F(i+1, j), F(i+1, j+1)];
                m2 = [1, 1;
                      0, 1];
                coef(:,:, i, j) = inv(m1) * fMat * inv(m2);
            endfor
        endfor
    else # Metodo Bicubico
        coef = zeros(4, 4, (nx-1),(ny-1));
        for i = 1:nx-1
            for j = 1:ny-1
                m1 = [1, 0,    0,    0;
                      1, 1,    1,    1;
                      0, 1/hx, 0,    0;
                      0, 1/hx, 2/hx, 3/hx];
                fMat = [F(i,j),     F(i, j+1),     dyF(i,j),    dyF(i,j+1);
                        F(i+1,j),   F(i+1, j+1),   dyF(i+1,j),  dyF(i+1,j+1);
                        dxF(i,j),   dxF(i, j+1),   dxyF(i,j),   dxyF(i,j+1);
                        dxF(i+1,j), dxF(i+1, j+1), dxyF(i+1,j), dxyF(i+1,j+1);];
                m2 = [1, 1, 0,    0;
                      0, 1, 1/hy, 1/hy;
                      0, 1, 0,    2/hy;
                      0, 1, 0,    3/hy]; 
                coef(:,:, i, j) = inv(m1) * fMat * inv(m2);
            endfor
        endfor
    endif
end

################################################################################
function draw(titulo, x, y, F)
    nMin = min(min(F));
    nMax = max(max(F));
    #colorMat = ceil(255 .* (F .- nMin)./(nMax + abs(nMin)));
    colorMat = zeros(length(x), length(y));
    for i = 1:length(x)
        for j = 1:length(y)
            if (nMax != nMin)
                colorMat(i, j) = ceil(255*(F(i, j) - nMin)/(nMax + abs(nMin)));
            else
                colorMat(i, j) = 0;
            endif    
        endfor
    endfor
    c = transpose(linspace(0, 1, 256));
    colormap([c,c,c]);
    imagesc(x, y, colorMat);
    title(titulo);
    xlabel("x"); ylabel("y");
end 