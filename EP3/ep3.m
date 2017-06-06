################################################################################
#                                                                              #
#                  EP3: Interpolacao e diferenciacao numerica                  #
#                                                                              #
#                       Pedro Pereira     - NUSP 9778794                       #
#                       Raphael R. Gusmao - NUSP 9778561                       #
#                                                                              #
################################################################################
1;

################################################################################
# Interpolacao de imagem
function interpolaImagem()
    # Entrada dos valores
    #fileName = input("Digite o nome da imagem: ");
    #scale = input("Digite o fator de escala para a descompressao: ");
    fileName = 'sgt100.jpg'; scale = 5;# Teste
    
    # Imagem original
    img = imread(fileName);
    imgX = size(img,2); imgY = size(img,1);
    
    # Comprime a imagem original
    comp = compress(img, scale);
    compX = size(comp,2); compY = size(comp,1);
    
    # Descomprime a imagem comprimida
    dec = decompress(comp, scale);
    decX = size(dec,2); decY = size(dec,1);
    
    # Plota a imagem original, a comprimida e a descomprimida
    clf;
    subplot(1,3,1);
     imshow(img);
     title(strcat("[",num2str(imgX),"x",num2str(imgX),"] Imagem original"));
    subplot(1,3,2);
     imshow(comp);
     title(strcat("[",num2str(compX),"x",num2str(compY),"] Imagem comprimida"));
    subplot(1,3,3);
     imshow(dec);
     title(strcat("[",num2str(decX),"x",num2str(decY),"] Imagem descomprimida"));
end

################################################################################
# Interpolacao de funcao
function interpolaFuncao()
    # Entrada dos valores
    #ax = input("Digite ax: "); bx = input("Digite bx: ");
    #ay = input("Digite ay: "); by = input("Digite by: ");
    #hx = input("Digite hx: "); hy = input("Digite hy: ");
    #scale = input("Digite scale: ");
    #disp("Escolha uma das funcoes abaixo");
    #disp(" 1: f(x,y) = xy");
    #disp(" 2: f(x,y) = x + y");
    #disp(" 3: f(x,y) = x^2 - 2y + 2");
    #disp(" 4: f(x,y) = sen(x^2) + 3cos(y)");
    #nFun = input(" : ");
    ax = 0; bx = 4; ay = 0; by = 4; hx = 1; hy = 1; nFun = 1; scale = 10;# Teste
    
    # Escolha da funcao
    f = 0;
    if (nFun == 1) # f(x,y) = xy
        f = @(x, y) x.*y;
    elseif (nFun == 2) # f(x,y) = x + y
        f = @(x, y) x + y;
    elseif (nFun == 3) # f(x,y) = x^2 - 2y + 2
        f = @(x, y) x.^2 - 2*y + 2;
    else # f(x,y) = sen(x^2) + 3cos(y)
        f = @(x, y) sin(x^2) + 3*cos(y);
    endif
    
    # Quantidade de pontos na malha
    nx = 1+(bx-ax)/hx; ny = 1+(by-ay)/hy;
    
    # n pontos da 'malha grossa' distribuidos uniformemente entre a e b
    X = linspace(ax, bx, nx);
    Y = linspace(ay, by, ny);
    
    # Matriz com os pontos f(x,y)
    [X_, Y_] = meshgrid(X, Y);
    F = f(X_, Y_);
    
    # Matriz dos coeficientes
    coef = constroiv(ax, bx, ay, by, hx, hy, nx, ny, F);
    
    # Inicializa a matriz das aproximacoes v(x,y)
    V = zeros(nx*scale, ny*scale);
    
    # n*scale pontos da 'malha fina' distribuidos uniformemente entre a e b
    Xs = linspace(ax, bx, nx*scale);
    Ys = linspace(ay, by, ny*scale);
    
    # Percorre a 'malha fina' e avalia v em todos os pontos (x,y)
    for i = 1:nx*scale
        for j = 1:ny*scale
            V(i,j) = avaliav(Xs(i), Ys(j), ax, bx, ay, by, hx, hy, nx, ny, coef);
        endfor
    endfor
    
    # Plota f e v
    clf;
    subplot(1,2,1);
     draw("f", X, Y, F);
    subplot(1,2,2);
     draw("v", Xs, Ys, V);
end

################################################################################
# Comprime uma imagem
function [comp] = compress(img, scale)
    # Quantidade de pixels da imagem comprimida
    nx = max(1, size(img, 2)/scale); ny = max(1, size(img, 1)/scale);
    
    # Matrizes com as componentes RGB da imagem
    R = double(img(:,:,1));
    G = double(img(:,:,2));
    B = double(img(:,:,3));
    
    # Inicializa a matriz da imagem comprimida
    comp = zeros(ny, nx, 3);
    
    # Seleciona apenas uma 'malha grossa' da imagem original
    for i = 1:ny
        for j = 1:nx
            comp(i,j,:) = [R(i*scale,j*scale);
                           G(i*scale,j*scale);
                           B(i*scale,j*scale)];
        endfor
    endfor
    
    # Converte a matriz com para o formato correto para imagem
    comp = uint8(comp);
end

################################################################################
# Descomprime uma imagem
function [dec] = decompress(img, scale)
    # Quantidade de pixels da imagem comprimida
    nx = size(img, 2); ny = size(img, 1);
    
    # Dimensoes da imagem
    ax = 1; bx = nx; ay = 1; by = ny;
    hx = 1; hy = 1;
    
    # Matrizes com as componentes RGB da imagem
    R = double(img(:,:,1));
    G = double(img(:,:,2));
    B = double(img(:,:,3));
    
    # Matriz dos coeficientes das componentes RGB
    coefR = constroiv(ax, bx, ay, by, hx, hy, nx, ny, R);
    coefG = constroiv(ax, bx, ay, by, hx, hy, nx, ny, G);
    coefB = constroiv(ax, bx, ay, by, hx, hy, nx, ny, B);
    
    # Inicializa as matrize das aproximacoes v para as componentes RGB
    vR = zeros(nx*scale, ny*scale);
    vG = zeros(nx*scale, ny*scale);
    vB = zeros(nx*scale, ny*scale);
    
    # Inicializa a matriz da imagem descomprimida
    dec = zeros(ny*scale, nx*scale, 3);
    
    # n*scale pontos da malha fina distribuidos uniformemente entre a e b
    X = linspace(ax, bx, nx*scale);
    Y = linspace(ay, by, ny*scale);
    
    # Percorre a malha e avalia v em todos os pontos (x,y)
    for i = 1:nx*scale
        for j = 1:ny*scale
            vR(i,j) = avaliav(X(i), Y(j), ax, bx, ay, by, hx, hy, nx, ny, coefR);
            vG(i,j) = avaliav(X(i), Y(j), ax, bx, ay, by, hx, hy, nx, ny, coefG);
            vB(i,j) = avaliav(X(i), Y(j), ax, bx, ay, by, hx, hy, nx, ny, coefB);
            dec(j,i,:) = [vR(i,j); vG(i,j); vB(i,j)];
        endfor
    endfor
    
    # Converte a matriz dec para o formato correto para imagem
    dec = ceil(uint8(dec));
end

################################################################################
# Avalia v em um ponto (x,y)
function ret = avaliav(x, y, ax, bx, ay, by, hx, hy, nx, ny, coef)
    # n pontos da 'malha grossa' distribuidos uniformemente entre a e b
    X = linspace(ax, bx, nx);
    Y = linspace(ay, by, ny);
    
    # Encontra o ponto superior esquerdo mais proximo de (x,y)
    i = 1;
    while (i+1 < nx && X(i+1) < x)
        i = i + 1;
    endwhile
    j = 1;
    while (j+1 < ny && Y(j+1) < y)
        j = j + 1;
    endwhile
    
    # Calcula v(x,y) = uma aproximacao de f(x,y)
    m1 = [1, (x - X(i))/hx, ((x - X(i))/hx)^2, ((x - X(i))/hx)^3];
    m2 = [1; (y - Y(j))/hy; ((y - Y(j))/hy)^2; ((y - Y(j))/hy)^3];
    ret = m1 * coef(:,:, i, j) * m2;
end

################################################################################
# Constroi a matriz dos coeficientes para calcular v(x,y)
function coef = constroiv(ax, bx, ay, by, hx, hy, nx, ny, F)
    # Matrizes das aproximacao das derivadas de f
    [dxF, dyF, dxyF] = aproxdf(ax, bx, ay, by, hx, hy, nx, ny, F);
    F = transpose(F);
    dxF = transpose(dxF);
    dyF = transpose(dyF);
    dxyF = transpose(dxyF);
    
    # Inicializa a matriz dos coeficientes
    coef = zeros(4, 4, (nx-1),(ny-1));
    
    # Calcula a matriz dos coeficientes
    for i = 1:nx-1
        for j = 1:ny-1
            m1 = [1, 0,    0,    0;
                  1, 1,    1,    1;
                  0, 1/hx, 0,    0;
                  0, 1/hx, 2/hx, 3/hx];
            fMat = [  F(i,   j),   F(i,   j+1),  dyF(i,   j),  dyF(i,   j+1);
                      F(i+1, j),   F(i+1, j+1),  dyF(i+1, j),  dyF(i+1, j+1);
                    dxF(i,   j), dxF(i,   j+1), dxyF(i,   j), dxyF(i,   j+1);
                    dxF(i+1, j), dxF(i+1, j+1), dxyF(i+1, j), dxyF(i+1, j+1)];
            m2 = [1, 1, 0,    0;
                  0, 1, 1/hy, 1/hy;
                  0, 1, 0,    2/hy;
                  0, 1, 0,    3/hy];
            coef(:,:, i, j) = inv(m1) * fMat * inv(m2);
        endfor
    endfor
end

################################################################################
# Encontra aproximacoes O(h^2) para dxf, dyf e dxyf em todos os pontos da malha
function [dxF, dyF, dxyF] = aproxdf(ax, bx, ay, by, hx, hy, nx, ny, F)
    # Utiliza a transposta de F (para facilitar o codigo)
    F = transpose(F);
    
    # Inicializa as matrizes das derivadas
    dxF = zeros(nx, ny);
    dyF = zeros(nx, ny);
    dxyF = zeros(nx, ny);
    
    # Percorre a matriz F e encontra as derivadas nos pontos
    for i = 1:nx-1
        for j = 1:ny-1
            dxF(i,j) = (F(i+1, j) - F(i, j))/hx;
            dyF(i,j) = (F(i, j+1) - F(i, j))/hy;
            dxyF(i,j) = (F(i+1, j+1) - F(i+1, j) - F(i, j+1) + F(i, j))/(hx*hy);
        endfor
    endfor
    
    # Percorre as extremidades da matriz F
    i = nx; j = ny;
    for k = 2:ny-1
        # Extremidade direita
        dxF(i,k) = (F(i, k) - F(i-1, k))/hx;
        dyF(i,k) = (F(i, k) - F(i, k-1))/hy;
        dxyF(i,k) = (F(i, k) - F(i, k-1) - F(i-1, k) + F(i-1, k-1))/(hx*hy);
        # Extremidade inferior
        dxF(k,j) = (F(k, j) - F(k-1, j))/hx;
        dyF(k,j) = (F(k, j) - F(k, j-1))/hy;
        dxyF(k,j) = (F(k, j) - F(k, j-1) - F(k-1, j) + F(k-1, j-1))/(hx*hy);
    endfor
    
    # Ponto da extremidade superior direita
    i = nx; j = 1;
    dxF(i,j) = (F(i, j) - F(i-1, j))/hx;
    dyF(i,j) = (F(i, j+1) - F(i, j))/hy;
    dxyF(i,j) = (F(i, j+1) - F(i, j) - F(i-1, j+1) + F(i-1, j))/(hx*hy);
    
    # Ponto da extremidade inferior esquerda
    i = 1; j = ny;
    dxF(i,j) = (F(i+1, j) - F(i, j))/hx;
    dyF(i,j) = (F(i, j) - F(i, j-1))/hy;
    dxyF(i,j) = (F(i+1, j) - F(i+1, j-1) - F(i, j) + F(i, j-1))/(hx*hy);
    
    # Ponto da extremidade inferior direita
    i = nx; j = ny;
    dxF(i,j) = (F(i, j) - F(i-1, j))/hx;
    dyF(i,j) = (F(i, j) - F(i, j-1))/hy;
    dxyF(i,j) = (F(i, j) - F(i, j-1) - F(i-1, j) + F(i-1, j-1))/(hx*hy);
    
    # Calcula as transpostas das derivadas (para facilitar o codigo)
    dxF = transpose(dxF);
    dyF = transpose(dyF);
    dxyF = transpose(dxyF);
end

################################################################################
# Plota a matriz F em escala de cinza (valores maiores <=> cores mais claras) 
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
    title(titulo); xlabel("x"); ylabel("y");
end